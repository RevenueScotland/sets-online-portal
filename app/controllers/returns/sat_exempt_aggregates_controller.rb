# frozen_string_literal: true

module Returns
  # Provides sites/exempt aggregate specific controller functionality.
  class SatExemptAggregatesController < ApplicationController
    include Wizard

    authorise requires: RS::AuthorisationHelper::SAT_SUMMARY

    # Exempt aggregate details wizard page
    def exempt_aggregate_details
      clear_cache = exempt_aggregate_new?
      Rails.logger.debug('New exempt aggregate entry') if clear_cache

      wizard_step(nil) do
        { setup_step: :setup_step, clear_cache: clear_cache, next_step: :site_summary_after_adding_aggregate,
          after_merge: :dump_exempt_aggregate_into_sat_wizard }
      end
    end

    # Delete the aggregate entry specified by uuid params[:exempt_aggregate]
    def destroy
      load_site
      delete_exempt_aggregate_entry(params[:exempt_aggregate])
      redirect_to(site_summary_after_adding_aggregate, status: :see_other)
    end

    private

    # Sets up wizard model if it doesn't already exist in the cache
    # Exempt_aggregates are indexed by UUID so we don't get the wrong one when editing or deleting them.
    # @raise [Error::AppError] if the exempt aggregate id is missing (provided as a param)
    # @return [ExemptAggregate] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path

      # load site before setup model
      load_site

      # load existing or setup new exempt_aggregate on first entering the step
      unless params[:continue] || params[:exempt_aggregate].nil? || exempt_aggregate_new?
        @exempt_aggregate = load_exempt_aggregate
        return @exempt_aggregate
      end

      # reload existing exempt_aggregate entry from the wizard or create a new one
      @exempt_aggregate = wizard_load || Sat::ExemptAggregate.new(rate_date: @site.rate_date,
                                                                  site_name: @site.site_name)

      @exempt_aggregate
    end

    # Extract exempt_aggregate object from the site's list and save it in the wizard cache.
    # @return [ExemptAggregate] loaded object
    # @raise [Error::AppError] if the exempt_aggregate doesn't exist
    def load_exempt_aggregate
      # ID of the object to load
      uuid = params[:exempt_aggregate]
      unless @site.exempt_aggregates.key?(uuid)
        raise Error::AppError.new('Exempt Aggregates',
                                  "Can't find index #{uuid}")
      end

      @exempt_aggregate = @site.exempt_aggregates[uuid]
      wizard_save(@exempt_aggregate)

      @exempt_aggregate
    end

    # Remove a exempt_aggregate entry from the current site
    # @param uuid [SecureRandom.uuid] the exempt aggregate's ID in the current site's list
    def delete_exempt_aggregate_entry(uuid)
      Rails.logger.debug { "Deleting Exempt Aggregate entry #{uuid} from site #{@site.site_name}" }

      # check have required info
      load_site if @site.nil?

      # check the key exists
      unless @site.exempt_aggregates&.key?(uuid)
        raise Error::AppError.new('EXEMPT_AGGREGATE', "Cannot find index #{uuid}")
      end

      # remove from the site model
      @site.exempt_aggregates&.delete(uuid)

      # update SAT wizard (@site is part of @sat_return)
      wizard_save(@sat_return, SatController)

      # clear exempt_aggregate wizard for good measure
      wizard_end
    end

    # The standard way of using the path of the site summary details, which is used after
    # adding a new exempt_aggregate type.
    def site_summary_after_adding_aggregate
      returns_sat_site_summary_path(@site)
    end

    # Sets up @site (and @sat_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SatController's wizard cache.
    def load_site
      site_id = selected_site
      Rails.logger.debug { "Loading site #{site_id} for exempt aggregate" }
      @sat_return = wizard_load_or_redirect(returns_sat_summary_url, nil, SatController)
      # If they have entered part way through they may have a return with no sites so send them back
      raise Error::WizardRedirectError, returns_sat_summary_url if @sat_return.sites.nil?

      @site = @sat_return.sites[site_id]
    end

    # @return [Integer] the selected site_id from the session
    def selected_site
      session[:returns_sat_site]
    end

    # Determines if the param id :exempt_aggregate consists of the value 'new'.
    # Normally used in the creation of a new exempt_aggregate type or editing an existing exempt_aggregate.
    # @return [Boolean] does the exempt_aggregate param consist of value 'new'?
    def exempt_aggregate_new?
      params[:exempt_aggregate] == 'new'
    end

    # Puts the SatExemptAggregatesController wizard data (ie @exempt_aggregate @see #setup_step)
    # into the main SAT Wizard cache
    # @return [Boolean] true if successful
    def dump_exempt_aggregate_into_sat_wizard
      # make sure we have the site set up
      load_site
      @site.exempt_aggregates = {} if @site.exempt_aggregates.nil?

      # insert the exempt_aggregate into @site and save @sat_return (@site is part of @sat_return)
      @site.exempt_aggregates[@exempt_aggregate.uuid] = @exempt_aggregate

      wizard_save(@sat_return, SatController)
      wizard_end # clear the exempt_aggregate cache
      true
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [ExemptAggregate] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @exempt_aggregate = wizard_load_or_redirect(returns_sat_site_summary_url)
      @exempt_aggregate
    end

    # Return the parameter list filtered for the attributes of the ExemptAggregate model.
    def filter_params(_sub_object_attribute = nil)
      required = :returns_sat_exempt_aggregate
      attribute_list = Returns::Sat::ExemptAggregate.attribute_list

      return unless params[required]

      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
