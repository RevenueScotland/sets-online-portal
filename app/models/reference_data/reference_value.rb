# frozen_string_literal: true

module ReferenceData
  # Represents a CV item and provides cached, filtered access to back office Code-Value lists
  # (eg configurations, lists of data etc).
  # The complete list of reference values is long, so they are retrieved and cached.
  # The lists are grouped by DomainCode, ServiceCode and Workplace code.
  # @see BackOfficeDataCaching#lookup (and similar methods) for how to call this class.
  class ReferenceValue < SystemParameter # rubocop:disable Metrics/ClassLength
    include DateFormatting
    # additional fields
    attr_accessor :default, :sequence, :text, :usage

    # override the sort sequence to be the provided sequence if present
    def sort_key
      # Make sure sequence is at least 6 long to maintain numeric sorting
      @sequence&.rjust(6, '0') || @code
    end

    # Returns the full key code of this object including the composite key
    def full_key_code
      "#{code}>$<#{composite_key}"
    end

    # Create a new instance of this class using the back office data given
    # @param data [Hash] data from the back office response
    # @note returns [Object] a new instance
    private_class_method def self.make_object(data)
      ReferenceValue.new(domain_code: data[:domain_code], service_code: data[:service_code],
                         workplace_code: data[:workplace_code], code: data[:code], value: data[:name],
                         text: data[:comment], default: data[:default], sequence: data[:sequence], usage: data[:usage])
    end

    # Calls the correct service and specifies where the results are in the response body
    private_class_method def self.back_office_data
      lookup_back_office_data(:get_reference_values, :reference_values)
    end

    # @!method self.application_values(existing_values)
    # CV lists which we need for the application but which don't exist in the back office.
    # @param existing_values [Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    private_class_method def self.application_values(existing_values) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      output = {}
      # example code :
      # output[composite_key] = { 'code' => System_Parameter.new(code: 'code', value: 'value') }
      # or for multiple codes under the same composite key :
      # app_codes = { 'Y' => ReferenceValue.new(code: 'Y', value: 'Current') }
      # output[composite_key('domain', 'service', 'workplace')] = app_codes
      # app_codes = { 'Y' => ReferenceValue.new(code: 'Y', value: 'Current'),
      #               'N' => ReferenceValue.new(code: 'N', value: 'Inactive') }
      output[format_composite_key('CURRENT_INACTIVE', 'SYS', 'RSTU')] = current_inactive
      output[format_composite_key('DIRECTION', 'SYS', 'RSTU')] = direction
      output[format_composite_key('MESSAGE_SORT_TYPES', 'SYS', 'RSTU')] = messages_sort_by
      output[format_composite_key('RETURN_STATUS', 'SYS', 'RSTU')] = return_status
      output[format_composite_key('RETURN_SORT_TYPES', 'SYS', 'RSTU')] = return_sort_types
      output[format_composite_key('BUYER TYPES', 'SYS', 'RSTU')] = buyer_types
      output[format_composite_key('EFFECTIVE_DATE_CHECKER', 'SYS', 'RSTU')] = effective_date_checker
      output[format_composite_key('ELIGIBILITY_LIST', 'SYS', 'RSTU')] = eligibility_checkers
      output[format_composite_key('ELIGIBILITY_LIST_AFTER', 'SYS', 'RSTU')] = eligibility_checkers_after

      output[format_composite_key('RENEWALORREVIEW', 'SYS', 'RSTU')] = renewal_or_review
      output[format_composite_key('RESTORATION-TYPE', 'SLFT', 'RSTU')] = restoration_type
      output[format_composite_key('TRANSACTIONS_SORT', 'SYS', 'RSTU')] = trans_sort_type

      # merge the two EWC hashes into one
      output[format_composite_key('EWC_LIST', 'SLFT', 'RSTU')] = merge_ewc_codes(existing_values)
      # merge the three message subject lists into one
      output[format_composite_key('ALL_MESSAGE_SUBJECT', 'SYS', 'RSTU')] = merge_message_subjects(existing_values)
      # Creating new Return type list by including new list for sort
      output[format_composite_key('ALL RETURN TYPE', 'LBTT', 'RSTU')] = merge_lbtt_return_types(existing_values)
      output[format_composite_key('ALL RETURN TYPE', 'SLFT', 'RSTU')] =
        existing_values[format_composite_key('RETURN TYPE', 'SLFT', 'RSTU')]
      output[format_composite_key('ALL RETURN TYPE', 'SAT', 'RSTU')] =
        existing_values[format_composite_key('RETURN TYPE', 'SAT', 'RSTU')]
      output[format_composite_key('TRANSACTION GROUPS TEXT', 'LBTT', 'RSTU')] =
        transaction_group(existing_values, 'LBTT')
      output[format_composite_key('TRANSACTION GROUPS TEXT', 'SLFT', 'RSTU')] =
        transaction_group(existing_values, 'SLFT')
      output[format_composite_key('TRANSACTION GROUPS TEXT', 'SAT', 'RSTU')] =
        transaction_group(existing_values, 'SAT')

      output
    end

    # @return [hash] The internal current inactive list
    private_class_method def self.current_inactive
      {
        'Y' => ReferenceValue.new(code: 'Y', value: 'Current', sequence: '10'),
        'N' => ReferenceValue.new(code: 'N', value: 'Inactive', sequence: '20')
      }
    end

    # @return [hash] The internal direction list
    private_class_method def self.direction
      {
        'O' => ReferenceValue.new(code: 'O', value: 'Received'),
        'I' => ReferenceValue.new(code: 'I', value: 'Sent')
      }
    end

    # @return [hash] The internal sorting list of messages
    private_class_method def self.messages_sort_by
      {
        'MostRecent' => ReferenceValue.new(code: 'MostRecent', value: 'Most recent', sequence: '10'),
        'Oldest' => ReferenceValue.new(code: 'Oldest', value: 'Oldest', sequence: '20'),
        'ReturnReference' => ReferenceValue.new(code: 'ReturnReference', value: 'Reference', sequence: '30'),
        'SenderName' => ReferenceValue.new(code: 'SenderName', value: 'Sender name', sequence: '40'),
        'Subject' => ReferenceValue.new(code: 'Subject', value: 'Subject', sequence: '50')
      }
    end

    # @return [hash] The internal sorting list of returns
    private_class_method def self.return_sort_types
      {
        'MostRecent' => ReferenceValue.new(code: 'MostRecent', value: 'Most recent', sequence: '10'),
        'Oldest' => ReferenceValue.new(code: 'Oldest', value: 'Oldest', sequence: '20'),
        'BalanceDesc' => ReferenceValue.new(code: 'BalanceDesc', value: 'Balance : High - Low', sequence: '30'),
        'BalanceAsc' => ReferenceValue.new(code: 'BalanceAsc', value: 'Balance : Low - High', sequence: '40'),
        'ReturnReference' => ReferenceValue.new(code: 'ReturnReference', value: 'Return reference', sequence: '50'),
        'YourReference' => ReferenceValue.new(code: 'YourReference', value: 'Your reference', sequence: '60'),
        'Description' => ReferenceValue.new(code: 'Description', value: 'Description', sequence: '70')
      }
    end

    # @return [hash] The slft application type list
    private_class_method def self.restoration_type
      {
        'PART' => ReferenceValue.new(code: 'PART', value: 'Part', sequence: '10'),
        'FULL' => ReferenceValue.new(code: 'FULL', value: 'Full', sequence: '20')
      }
    end

    # @return [hash] The internal sorting options for transactions
    private_class_method def self.trans_sort_type
      {
        'MostRecent' => ReferenceValue.new(code: 'MostRecent', value: 'Most recent', sequence: '10'),
        'Oldest' => ReferenceValue.new(code: 'Oldest', value: 'Oldest', sequence: '20'),
        'AmountDesc' => ReferenceValue.new(code: 'AmountDesc', value: 'Amount : High - Low', sequence: '30'),
        'AmountAsc' => ReferenceValue.new(code: 'AmountAsc', value: 'Amount : Low - High', sequence: '40'),
        'BalanceDesc' => ReferenceValue.new(code: 'BalanceDesc', value: 'Balance : High - Low', sequence: '50'),
        'BalanceAsc' => ReferenceValue.new(code: 'BalanceAsc', value: 'Balance : Low - High', sequence: '60'),
        'RelatedReference' => ReferenceValue.new(code: 'RelatedReference', value: 'Related reference', sequence: '70'),
        'Description' => ReferenceValue.new(code: 'Description', value: 'Description', sequence: '80')
      }
    end

    # @return [hash] The slft application type list
    private_class_method def self.renewal_or_review
      {
        'RENEWAL' => ReferenceValue.new(code: 'RENEWAL', value: 'Renewal', sequence: '10'),
        'REVIEW' => ReferenceValue.new(code: 'REVIEW', value: 'Review', sequence: '20')
      }
    end

    # @return [hash] The internal return status
    private_class_method def self.return_status
      {
        'L' => ReferenceValue.new(code: 'L', value: 'Filed'),
        'D' => ReferenceValue.new(code: 'D', value: 'Draft')
      }
    end

    # @return [hash] The internal buyer_typoes
    private_class_method def self.buyer_types
      {
        'PRIVATE' => ReferenceValue.new(code: 'PRIVATE', value: 'A private individual', sequence: '10'),
        'REG_COM' => ReferenceValue.new(code: 'REG_COM', value: 'An organisation registered with Companies House',
                                        sequence: '20'),
        'OTHERORG' => ReferenceValue.new(code: 'OTHERORG', value: 'An other organisation', sequence: '30')
      }
    end

    # @return [hash] the effective date checker
    def self.effective_date_checker # rubocop:disable Metrics/MethodLength
      ads_leg_eff_date = Date.parse(ReferenceData::SystemParameter.lookup(
        'COMMON', 'LBTT', 'RSTU', safe_lookup: true
      )['ADS_LEG_EFFECT_DATE']&.value)

      ads_leg_eff_date_past = DateFormatting.to_display_date_suffix_format(ads_leg_eff_date - 1)
      ads_leg_eff_date = DateFormatting.to_display_date_suffix_format(ads_leg_eff_date)

      value1 = "My transaction has an effective date of #{ads_leg_eff_date_past} or earlier"
      value2 = "My transaction has an effective date of #{ads_leg_eff_date} or later"
      {
        'BEFORE_DATE' => ReferenceValue.new(code: 'BEFORE_DATE', value: value1, sequence: '10'),
        'AFTER_DATE' => ReferenceValue.new(code: 'AFTER_DATE', value: value2, sequence: '20')
      }
    end

    # @return [hash] The internal buyer_types
    def self.eligibility_checkers
      {
        '0' => ReferenceValue.new(code: '0', value: 'ADS was paid on the new property purchase.', sequence: '10'),
        '1' => ReferenceValue.new(code: '1', value: 'The previous property was sold within 18 months ' \
                                                    'of buying the new one.', sequence: '20'),
        '2' => ReferenceValue.new(code: '2', value: 'The new property is, or has been, ' \
                                                    'the only or main residence of all buyers.', sequence: '30'),
        '3' => ReferenceValue.new(code: '3', value: 'The previous property was the only or main residence of all ' \
                                                    'buyers of the new property at some time in the 18 month ' \
                                                    'period before the new property was purchased.', sequence: '40')
      }
    end

    # @return [hash] The eligibility check
    def self.eligibility_checkers_after
      { '0' => ReferenceValue.new(code: '0', value: 'ADS was paid on the new property purchase.', sequence: '10'),
        '1' => ReferenceValue.new(code: '1', value: 'The previous property was sold within 36 months ' \
                                                    'of buying the new one.', sequence: '20'),
        '2' => ReferenceValue.new(code: '2', value: 'The new property is, or has been, ' \
                                                    'the only or main residence of all buyers.', sequence: '30'),
        '3' => ReferenceValue.new(code: '3', value: 'The previous property was the only or main residence of all ' \
                                                    'relevant buyers ' \
                                                    'of the new property at some time in the 36 month ' \
                                                    'period before the new property was purchased.', sequence: '40') }
    end

    # Merge the two EWC lists together and sort
    # @return [hash] sorted EWC reference data codes list
    private_class_method def self.merge_ewc_codes(existing_values)
      haz = existing_values[format_composite_key('EWCHAZARDOUS', 'SLFT', 'RSTU')]
      non = existing_values[format_composite_key('EWCNONHAZARDOUS', 'SLFT', 'RSTU')]
      haz.merge!(non)
    end

    # Merge the return type Lease (all types) to existing LBTT return types
    # @return [hash] merged LBTT return types reference data
    private_class_method def self.merge_lbtt_return_types(existing_values)
      lbtt_types = existing_values[format_composite_key('RETURN TYPE', 'LBTT', 'RSTU')]
      lease_all = { 'ALL_LEASE_TYPES' => ReferenceValue.new(code: 'ALL_LEASE_TYPES',
                                                            value: 'Lease (all types)', sequence: '1') }
      lbtt_types.merge(lease_all)
    end

    # Merge the three subject lists into one, with a key value based on the full key
    # @return [hash] sorted EWC reference data codes list
    private_class_method def self.merge_message_subjects(existing_values)
      output = {}
      # RSTP-1602 : Create composite keys dynamically
      comp_keys = %w[LBTT SLFT SYS SAT].map { |x| format_composite_key('MESSAGE_SUBJECT', x, 'RSTU') }

      comp_keys.each do |comp_key|
        existing_values[comp_key]&.each_value do |value|
          output[value.full_key_code] = value
        end
      end

      output
    end

    # Overrides the value of object to text
    # @return [hash] List of transaction group
    private_class_method def self.transaction_group(existing_values, srv_code)
      output = {}

      existing_values[format_composite_key('TRANSACTION GROUPS', srv_code, 'RSTU')]&.each_value do |obj|
        obj.value = obj.text
        output[obj] = obj
      end

      output
    end
  end
end
