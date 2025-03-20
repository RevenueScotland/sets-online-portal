# frozen_string_literal: true

module Returns
  # Provides sites/taxable aggregate specific controller functionality.
  class SatTaxableAggregatesController < ApplicationController
    include Wizard

    authorise requires: RS::AuthorisationHelper::SAT_SUMMARY

    # wizard steps in order
    STEPS = %w[aggregate_details aggregate_tonnage].freeze

    # aggregate details wizard step
    def aggregate_details
      clear_cache = aggregate_new?
      Rails.logger.debug('New taxable aggregate entry') if clear_cache

      wizard_step(STEPS) { { setup_step: :setup_step, clear_cache: clear_cache } }
    end

    # aggregate tonnage wizard step
    def aggregate_tonnage
      wizard_step(nil) do
        { next_step: :site_summary_after_adding_aggregate,
          after_merge: :dump_taxable_aggregate_into_sat_wizard }
      end
    end

    # Delete the taxable aggregate entry specified by aggregate uuid params[:aggregate]
    def destroy
      load_site
      delete_taxable_aggregate_entry(params[:aggregate])
      redirect_to(site_summary_after_adding_aggregate, status: :see_other)
    end

    private

    # Sets up wizard model if it doesn't already exist in the cache
    # TaxableAggregates are indexed by UUID so we don't get the wrong one when editing or deleting them.
    # @raise [Error::AppError] if the aggregate id is missing (provided as a param)
    # @return [TaxableAggregate] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path

      load_site

      # load existing or setup new TaxableAggregate on first entering the step
      unless params[:continue] || params[:aggregate].nil? || aggregate_new?
        @taxable_aggregate = load_aggregate
        return @taxable_aggregate
      end

      # reload existing taxable aggregate entry from the wizard or create a new one
      @taxable_aggregate = wizard_load || Sat::TaxableAggregate.new(rate_date: @site.rate_date,
                                                                    site_name: @site.site_name)

      @taxable_aggregate
    end

    # Extract taxable_aggregate object from the site's list and save it in the wizard cache.
    # @return [TaxableAggregate] loaded object
    # @raise [Error::AppError] if the taxable_aggregate doesn't exist
    def load_aggregate
      # ID of the object to load
      uuid = params[:aggregate]
      unless @site.taxable_aggregates.key?(uuid)
        raise Error::AppError.new('Taxable Aggregates',
                                  "Can't find index #{uuid}")
      end

      @taxable_aggregate = @site.taxable_aggregates[uuid]
      wizard_save(@taxable_aggregate)

      @taxable_aggregate
    end

    # Remove a taxable_aggregate entry from the current site
    # @param uuid [SecureRandom.uuid] the taxable aggregate's ID in the current site's list
    def delete_taxable_aggregate_entry(uuid)
      Rails.logger.debug { "Deleting Aggregate entry #{uuid} from site #{@site.site_name}" }

      # check have required info
      load_site if @site.nil?

      # check the key exists
      raise Error::AppError.new('AGGREGATE', "Cannot find index #{uuid}") unless @site.taxable_aggregates&.key?(uuid)

      # remove taxable aggregate from sites
      @site.taxable_aggregates&.delete(uuid)

      # update SAT wizard (@site is part of @sat_return)
      wizard_save(@sat_return, SatController)

      # clear taxable_aggregate wizard for good measure
      wizard_end
    end

    # The standard way of using the path of the site summary details, which is used after
    # adding a new taxable_aggregate type.
    def site_summary_after_adding_aggregate
      returns_sat_site_summary_path(@site)
    end

    # Sets up @site (and @sat_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SatController's wizard cache.
    def load_site
      site_id = selected_site
      Rails.logger.debug { "Loading site #{site_id} for taxable aggregate" }
      @sat_return = wizard_load_or_redirect(returns_sat_summary_url, nil, SatController)
      # If they have entered part way through they may have a return with no sites so send them back
      raise Error::WizardRedirectError, returns_sat_summary_url if @sat_return.sites.nil?

      @site = @sat_return.sites[site_id]
    end

    # @return [Integer] the selected site_id from the session
    def selected_site
      session[:returns_sat_site]
    end

    # Determines if the param id :aggregate consists of the value 'new'.
    # Normally used in the creation of a new taxable_aggregate type or editing an existing taxable_aggregate.
    # @return [Boolean] does the aggregate param consist of value 'new'?
    def aggregate_new?
      params[:aggregate] == 'new'
    end

    # Puts the SatTaxableAggregateController wizard data (ie @taxable_aggregate @see #setup_step)
    # into the main SAT Wizard cache
    # @return [Boolean] true if successful
    def dump_taxable_aggregate_into_sat_wizard
      # make sure we have the site set up
      load_site
      @site.taxable_aggregates = {} if @site.taxable_aggregates.nil?

      # insert the taxable_aggregate into @site and save @sat_return (@site is part of @sat_return)
      @site.taxable_aggregates[@taxable_aggregate.uuid] = @taxable_aggregate

      wizard_save(@sat_return, SatController)
      wizard_end # clear the taxable_aggregate cache
      true
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [TaxableAggregate] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @taxable_aggregate = wizard_load_or_redirect(returns_sat_site_summary_url)
      @taxable_aggregate
    end

    # Return the parameter list filtered for the attributes of the TaxableAggregate model.
    def filter_params(_sub_object_attribute = nil)
      attribute_list = Returns::Sat::TaxableAggregate.attribute_list
      required = :returns_sat_taxable_aggregate

      return unless params[required]

      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
