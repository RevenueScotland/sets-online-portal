# frozen_string_literal: true

module Returns
  module Sat
    # Adds Import functionality to the Sites model
    module SiteCsvImporting # rubocop:disable Metrics/ModuleLength
      extend ActiveSupport::Concern

      # Loads the CSV file into an array of rows, which are themselves arrays of data.
      # @param resource_item [Object] A resource item that represents the CSV file to be imported, any errors
      #   at a file level (can't open file, not a well formed CSV file) will be added to this resource_item
      # return [Array] array of imported data
      def import_site_csv_data(resource_item)
        parsed_data = import_data(resource_item)
        # If there's no data apart from header raise empty file error
        errors.add(:base, :file_empty) unless parsed_data.present? # rubocop:disable Rails/Blank
        return unless parsed_data.present? # rubocop:disable Rails/Blank

        # Check if any columns are missing
        missing_headers = (valid_csv_headers - parsed_data.headers)
        if missing_headers.present?
          errors.add(:base, :missing_columns,
                     columns: missing_headers.map(&:to_s).join(', '))
        end
        validate_and_import_data(parsed_data) unless parsed_data && missing_headers.present?
      end

      # Returns CSV data
      def import_data(resource_item)
        CSV.parse(resource_item.file_data, headers: true, header_converters: :symbol)
      rescue StandardError
        errors.add(:base, :reimport_file)
        []
      end

      private

      # Valid/ Expected column headers
      def valid_csv_headers
        %i[record_type company_name site_name period_start period_end aggregate_type_code
           comm_exploitation_type exploited_tonnage water_tonnage mixed_ind exemption_reason_code exempt_tonnage
           tax_credit_type tax_credit_period_start tax_credit_period_end tax_credit_tonnage]
      end

      # Validate and import data
      # The data is saved once all data rows are valid
      def validate_and_import_data(data) # rubocop:disable Metrics/MethodLength
        # The @error_statements is used to record error statements per row
        # The @valid_records is used to hold valid record(taxable) data
        @valid_records = []
        @error_statements = []
        data.each_with_index do |dt, idx|
          row_no = idx + 2
          @any_errors = []
          valid_record_type = valid_record_types.include? dt[:record_type]
          add_invalid_record_error(row_no) unless valid_record_type
          next unless valid_record_type

          find_and_save_site(dt, row_no)
        end
        save_row_errors
        dump_taxable_data if errors.empty?
      end

      # Add the invalid record type error to errors method
      def add_invalid_record_error(row)
        @any_errors.push(error_message('invalid_record_type'))
        @error_statements.push(I18n.t('returns.sat.csv_import.row_error', row: row,
                                                                          errors: @any_errors.join(', ')))
      end

      # Save row errors into the record
      # It shows total errors & displays errors (limit: 10)
      def save_row_errors
        return if @error_statements.empty?

        errors.add(:base, :errors_indicator,
                   error_count: @error_statements.length)
        # Iterate & add errors so the errors are shown separately on each row in portal
        @error_statements.first(10).each { |err| errors.add(:base, :error_stmts, errors: err) }
      end

      # Save all records once all validations are passed
      def dump_taxable_data
        # Insert the data if there is no data in the sites
        # Else save the data in csv_taxable_data
        site_data_empty = sites.map { |_x, y| y.missing_sat_details_data? }.all?(true)
        if site_data_empty
          @valid_records.each do |record|
            send(:"save_#{record[:type]}_data", record[:site], record[:record])
          end
        else
          self.csv_taxable_data = @valid_records
        end
      end

      # Find and validate site
      def find_and_save_site(data, row_no)
        site = fetch_site(data[:site_name])
        @error_statements.push(I18n.t('returns.sat.csv_import.invalid_site_name', row: row_no)) unless site.present? # rubocop:disable Rails/Blank
        validate_and_save_site_data(site, data, row_no) if site.present?
      end

      # Fetches translation with the given key
      def error_message(key)
        I18n.t("returns.sat.csv_import.#{key}")
      end

      # Validate site details - Company name, Period date details(start, end)
      def validate_and_save_site_data(sites, data, row) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        # Select site if multiple sites found OR select the site found
        site = if sites.length > 1
                 sites.select do |_x, y|
                   y.period_bdown_start == convert_date(data[:period_start])
                 end&.first&.[](1)
               else
                 sites&.first&.[](1)
               end
        # If site is not found, add it to errors
        if site.nil?
          @any_errors.push(error_message('invalid_period_start'))
          @error_statements.push(I18n.t('returns.sat.csv_import.row_error', row: row,
                                                                            errors: @any_errors.join(', ')))
        end
        return if site.nil?

        unless site.site_party_name&.downcase == data[:company_name]&.downcase
          @any_errors.push(error_message('invalid_company_name'))
        end
        @any_errors.push(error_message('invalid_period_start')) unless compare_dates(site.period_bdown_start,
                                                                                     convert_date(data[:period_start]))
        @any_errors.push(error_message('invalid_period_end')) unless compare_dates(site.period_bdown_end,
                                                                                   convert_date(data[:period_end]))
        parse_data_by_type(site, data[:record_type], data)
        return if @any_errors.empty?

        @error_statements.push(I18n.t('returns.sat.csv_import.row_error', row: row,
                                                                          errors: @any_errors.join(', ')))
      end

      # Save taxable aggregate data
      def save_taxable_aggregate_data(site, record)
        site.taxable_aggregates = {} if site.taxable_aggregates.nil?
        site.taxable_aggregates[record.uuid] = record
      end

      # Save Exempt aggregate data
      def save_exempt_aggregate_data(site, record)
        site.exempt_aggregates = {} if site.exempt_aggregates.nil?
        site.exempt_aggregates[record.uuid] = record
      end

      # Save Tax credit data (Credit claim)
      def save_tax_credit_data(site, record)
        site.credit_claims = {} if site.credit_claims.nil?
        site.credit_claims[record.uuid] = record
      end

      # Parse the row data depending on type of data
      def parse_data_by_type(site, record_type, data)
        send(:"validate_#{record_type.downcase}_data", site, data)
      end

      # Validate if the decimal value is greater than 1_000_000_000_000_000_000
      def maximum_value_exceeded?(val)
        val.to_i >= 1_000_000_000_000_000_000
      end

      # Validate if tonnage value has exceeded the highest limit
      def tonnage_limit_reached?(val)
        valid_decimal_string?(val) && maximum_value_exceeded?(val)
      end

      # Validate and save taxable data
      def validate_taxable_data(site, data)
        taxable_params = data.to_h.slice(:comm_exploitation_type, :exploited_tonnage,
                                         :water_tonnage, :mixed_ind)
        taxable_params[:aggregate_type] = data[:aggregate_type_code]&.strip
        taxable_params[:rate_date] = site.period_bdown_start
        taxable_params[:site_name] = site.site_name
        taxable_aggr = TaxableAggregate.new_from_fl(taxable_params)
        validate_taxable_ref_values(site, taxable_aggr)
      end

      # Validate the taxable aggregate record ref values
      def validate_taxable_ref_values(site, record)
        value_errors = tx_validation_errors(record)
        value_errors.concat(valid_tx_tonnage_comparison(record))
        @any_errors.push(record.errors.full_messages.join(', ')) unless record.valid?
        @any_errors.push(value_errors.join(', ')) if record.valid? && value_errors.present?
        add_taxable_aggregate(site, record) if record.valid? && value_errors.empty?
      end

      # Validates if water tonnage is greater than Exploited tonnage
      def valid_tx_tonnage_comparison(record)
        return [] unless valid_decimal_string?(record.exploited_tonnage) && valid_decimal_string?(record.water_tonnage)

        if BigDecimal(record.water_tonnage) > BigDecimal(record.exploited_tonnage)
          [error_message('water_tonnage_greater_err')]
        else
          []
        end
      end

      # Returns array of validation errors for the taxable aggregate record
      def tx_validation_errors(record)
        vl_errors = []
        vl_errors.concat(valid_tx_aggr_type_value(record))
        vl_errors.concat(valid_tx_expl_type_value(record))
        vl_errors.concat(valid_tx_weighing_method(record))
        vl_errors.concat(valid_tx_wt_tonnage(record))
        vl_errors.concat(valid_tx_expl_tonnage(record))
        vl_errors.concat(valid_tx_expl_tonnage_limit(record))
        vl_errors.concat(valid_tx_wt_tonnage_limit(record))
        vl_errors
      end

      # Validate water tonnage limit for tx record
      def valid_tx_wt_tonnage_limit(record)
        tonnage_limit_reached?(record.water_tonnage) ? [error_message('water_tonnage_value_exceeded')] : []
      end

      # Validate exploitation tonnage limit for tx record
      def valid_tx_expl_tonnage_limit(record)
        tonnage_limit_reached?(record.exploited_tonnage) ? [error_message('ex_tonnage_value_exceeded')] : []
      end

      # Validate aggregate value for tx record
      def valid_tx_aggr_type_value(record)
        valid_aggregate_type_values(record) ? [] : [error_message('invalid_aggr_type_code')]
      end

      # Validate exploitation type value for tx record
      def valid_tx_expl_type_value(record)
        valid_exploitation_code_values(record) ? [] : [error_message('invalid_expl_type_code')]
      end

      # Validate weighing method for tx record
      def valid_tx_weighing_method(record)
        %w[Y N].include?(record.mixed_ind) ? [] : [error_message('invalid_alt_weigh_method')]
      end

      # Validate water tonnage for tx record
      def valid_tx_wt_tonnage(record)
        valid_decimal_string?(record.water_tonnage) ? [] : [error_message('invalid_water_tonnage')]
      end

      # Validate water tonnage for tx record
      def valid_tx_expl_tonnage(record)
        valid_decimal_string?(record.exploited_tonnage) ? [] : [error_message('invalid_exploited_tonnage')]
      end

      # Validate exploitation code value
      def valid_exploitation_code_values(record)
        record.list_ref_data(:comm_exploitation_type).map(&:code).include?(record.comm_exploitation_type)
      end

      # Validate aggregate_type value
      def valid_aggregate_type_values(record)
        record.send(:aggregate_type_rates)&.map do |x| # rubocop:disable Rails/Pluck. Pluck isn't valid for the method
          x[:code]
        end&.include?(record.aggregate_type)
      end

      # Save the taxable aggregate, add it to set of valid records
      def add_taxable_aggregate(site, record)
        @valid_records.push({ site: site, type: 'taxable_aggregate', record: record })
      end

      # Validate & save exempt data
      def validate_exempt_data(site, data)
        exempt_params = data.to_h.slice(:exempt_tonnage)
        exempt_params[:aggregate_type] = data[:aggregate_type_code]&.strip
        exempt_params[:exempt_type] = data[:exemption_reason_code]&.strip
        exempt_params[:rate_date] = site.period_bdown_start
        exempt_params[:site_name] = site.site_name
        exempt_agg = ExemptAggregate.new_from_fl(exempt_params)
        validate_exempt_data_values(site, exempt_agg)
      end

      # Save the taxable aggregate, add it to set of valid records
      def add_exempt_aggregate(site, record)
        @valid_records.push({ site: site, type: 'exempt_aggregate', record: record })
      end

      # Validate exempt aggregate values
      def validate_exempt_data_values(site, record) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        value_errors = []
        value_errors.push(error_message('invalid_aggr_type_code')) unless valid_aggregate_type_values(record)
        value_errors.push(error_message('invalid_exempt_type_code')) unless valid_exempt_type_code(record)
        value_errors.push(error_message('invalid_exempt_tonnage')) unless valid_decimal_string? record.exempt_tonnage
        value_errors.push(error_message('exe_tonnage_value_exceeded')) if tonnage_limit_reached?(record.exempt_tonnage)
        @any_errors.push(record.errors.full_messages.join(', ')) unless record.valid?
        @any_errors.push(value_errors.join(', ')) if record.valid? && value_errors.present?
        add_exempt_aggregate(site, record) if record.valid? && value_errors.empty?
      end

      # Validate exempt type code
      def valid_exempt_type_code(record)
        record.list_ref_data(:exempt_type).map(&:code).include?(record.exempt_type)
      end

      # Validate & Save Credit data
      def validate_credit_data(site, data)
        credit_params = create_cl_params(site, data)
        cr = CreditClaim.new_from_fl(credit_params)
        validate_cl_data_values(site, cr, data)
      end

      # Returns a Hash of credit claim params while copying over site details into params
      def create_cl_params(site, data) # rubocop:disable Metrics/AbcSize
        param_hash = data.to_h.slice(:tax_credit_type)
        param_hash[:site_name] = site.site_name
        param_hash[:rate_date] = convert_date(data[:tax_credit_period_start])
        param_hash[:period_start] = site.period_bdown_start
        param_hash[:period_end] = site.period_bdown_end
        param_hash[:aggregate_type] = data[:aggregate_type_code]&.strip
        param_hash[:current_user] = current_user
        assign_tax_rel_values(param_hash, data, site)
      end

      # Assign tax relative values value to credit params hash
      def assign_tax_rel_values(cr_params, data, site)
        credit_period_start = convert_date(data[:tax_credit_period_start])
        credit_period_end = convert_date(data[:tax_credit_period_end])
        cr_params[:tax_period_ind] = if compare_dates(site.period_bdown_start, credit_period_start) &&
                                        compare_dates(site.period_bdown_end, credit_period_end)
                                       'Y'
                                     else
                                       'N'
                                     end
        cr_params[:tax_tonnage] = data[:tax_credit_tonnage]
        cr_params
      end

      # Validate cl credit type code value
      def valid_credit_type_values(record)
        record.list_ref_data(:tax_credit_type).map(&:code).include?(record.tax_credit_type)
      end

      # Validate aggregate_type value
      def valid_cl_aggregate_list_values(record)
        record.aggregate_types_list.map(&:code).include?(record.aggregate_type)
      end

      # Validate assigned CL values & add to @valid_records for further processing
      def validate_cl_data_values(site, record, data)
        value_errors = check_cl_validations(site, record, data)
        @any_errors.push(record.errors.full_messages.join(', ')) unless record.valid?
        @any_errors.push(value_errors.join(', ')) if record.valid? && value_errors.present?
        add_credit_claim(record, site) if record.valid? && value_errors.empty?
      end

      # Check CL validations and return errors if any
      def check_cl_validations(site, record, data)
        val_errors = []
        tax_period_errors = valid_credit_tax_periods(site, record, data)
        val_errors.push(tax_period_errors) if tax_period_errors.present?
        val_errors.concat(valid_cl_cr_rate(record))
        val_errors.concat(valid_cl_tx_tonnage(record))
        val_errors.concat(cl_tax_tonnage_exceeded(record))
        val_errors.concat(valid_cl_aggr_code(record))
        val_errors.concat(valid_cl_crd_code(record))
        val_errors
      end

      # Validate if tax tonnage has reached max value
      def cl_tax_tonnage_exceeded(record)
        tonnage_limit_reached?(record.tax_tonnage) ? [error_message('tax_tonnage_value_exceeded')] : []
      end

      # Validate if tax rate has exceeded the maximum value
      def cl_tax_rate_exceeded(record)
        tonnage_limit_reached?(record.tax_rate) ? [error_message('credit_rate_value_exceeded')] : []
      end

      # Validate CL credit type code
      def valid_cl_crd_code(record)
        valid_credit_type_values(record) ? [] : [error_message('invalid_credit_type_code')]
      end

      # Validate CL aggr type code
      def valid_cl_aggr_code(record)
        valid_cl_aggregate_list_values(record) ? [] : [error_message('invalid_aggr_type_code')]
      end

      # Validate CL credit rate
      def valid_cl_cr_rate(record)
        valid_decimal_string?(record.tax_rate) ? [] : [error_message('invalid_credit_rate')]
      end

      # Validate CL tax tonnage
      def valid_cl_tx_tonnage(record)
        valid_decimal_string?(record.tax_tonnage) ? [] : [error_message('invalid_credit_tonnage')]
      end

      # Add credit claim to valid record
      def add_credit_claim(record, site)
        @valid_records.push({ site: site, type: 'tax_credit', record: record })
      end

      # Validates if given string is valid decimal, it is non negative and has only two decimal places
      # Also validates is string is an invalid decimal
      # If string is not valid, returns false. So, we don't need to check
      # string present explicitly before calling this method
      def valid_decimal_string?(str)
        return false if str.blank? || str.nil?

        str.match?(/\A\d+(\.\d{1,2})?\z/)
      end

      # Returns a date range string
      # Example. 01/07/2024 to 31/07/2024
      def date_range_str(date1, date2)
        "#{date1.strftime('%d/%m/%Y')} to #{date2.strftime('%d/%m/%Y')}"
      end

      # Validate Return periods against the data in csv
      # Returns errors if any
      def valid_credit_tax_periods(site, record, data) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        value_errors = []
        value_errors.push(error_message('invalid_credit_period_start')) unless # rubocop:disable Rails/Blank
                                                                        convert_date(data[:tax_credit_period_start]).present? # Style/IfUnlessModifier # rubocop:disable Layout/LineLength
        value_errors.push(error_message('invalid_credit_period_end')) unless # rubocop:disable Rails/Blank
                                                                        convert_date(data[:tax_credit_period_end]).present? # Style/IfUnlessModifier # rubocop:disable Layout/LineLength
        return value_errors if value_errors.present?

        if record.tax_period_ind == 'Y'
          record.current_return = date_range_str(site.period_bdown_start, site.period_bdown_end)
        else
          period_str = date_range_str(convert_date(data[:tax_credit_period_start]),
                                      convert_date(data[:tax_credit_period_end]))
          # Validate the tax credit dates against previous returns
          return_code = record.list_all_previous_return_periods.filter_map do |x|
            x.code if x.value.include? period_str
          end
          value_errors.push(error_message('invalid_credit_period')) if return_code.empty?
          record.related_return = return_code.first if return_code.present?
        end
        value_errors
      end

      # Compare dates and return true/false. Assumption date1 will always be present
      def compare_dates(date1, date2)
        date1 == date2
      end

      # Converts/parses a date string
      def convert_date(date_str)
        Date.parse(date_str)
      rescue StandardError
        nil
      end

      # Find site details by matching csv data
      def fetch_site(site_name)
        sites.select { |_x, y| y.site_name&.downcase == site_name&.downcase }
      end

      # Returns the array of valid Record types
      def valid_record_types
        %w[TAXABLE EXEMPT CREDIT]
      end
    end
  end
end
