# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Manages the wizard steps that use the Relief calculations.
  # LBTT "About the reliefs" wizards and steps.
  class LbttReliefsController < ApplicationController
    include Wizard
    include WizardListHelper
    include LbttTaxHelper

    authorise requires: RS::AuthorisationHelper::LBTT_SUMMARY

    # store step flow of lbtt conveyance return transaction page name used for navigation
    STEPS = %w[reliefs_on_transaction multiple_dwellings_relief reliefs_calculation].freeze

    # Custom step in the Lbtt wizard which handle add row and merge_list method for this page
    def reliefs_on_transaction
      wizard_list_step(nil, setup_step: :setup_reliefs_on_transaction_step,
                            next_step: :calculate_next_step, cache_index: LbttController,
                            list_attribute: :relief_claims,
                            new_list_item_instance: :new_list_item_relief_claims,
                            loop: :start_next_step,
                            validates: :relief_claims,
                            after_merge: :update_tax_calculations)
    end

    # wizard step
    def multiple_dwellings_relief
      wizard_step(nil) do
        { next_step: :calculate_next_step, sub_object_attribute: :md_relief,
          loop: :multiple_dwellings_relief, cache_index: LbttController, after_merge: :update_tax_calculations }
      end
    end

    # reliefs calculation
    def reliefs_calculation
      wizard_list_step(returns_lbtt_summary_url,
                       list_validation_context: %i[relief_override_amount relief_override_amount_ads],
                       after_merge: :update_relief_type_calculation,
                       list_attribute: :relief_claims, new_list_item_instance: :new_list_item_relief_claims)
    end

    private

    # Custom setup for this step.  Calls @see #load_step to set up the model.
    def setup_reliefs_on_transaction_step
      model = load_step

      # initialise row data if not already present and this is a get not a post
      # posts are handled in the main list processing
      if @lbtt_return.relief_claims.blank? && request.get?
        @lbtt_return.relief_claims = Array.new(1) do
          new_list_item_relief_claims
        end
      end

      # get the ref data for relief types
      @relief_types = ReferenceData::TaxReliefType.filtered_list(
        @lbtt_return.flbt_type, current_only: true, show_ads_reliefs: @lbtt_return.show_ads?
      )

      model
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [Object] An array consisting of the Return and Relief Claim, or just the return
    def load_step(sub_object_attribute = nil)
      @post_path = wizard_post_path
      if sub_object_attribute.nil?
        @lbtt_return = wizard_load_or_redirect(returns_lbtt_summary_url, sub_object_attribute,
                                               Returns::LbttController)
      elsif sub_object_attribute == :md_relief
        @lbtt_return, @relief_claim = wizard_load_or_redirect(returns_lbtt_summary_url, sub_object_attribute,
                                                              Returns::LbttController)
      end
    end

    # change the page flow as lbtt return type
    # @return [String] the next step
    def calculate_next_step
      # return to summary if no relief claims, not use of symbol to work with
      return returns_lbtt_summary_path if @lbtt_return.relief_claims.blank?

      remove_mdr_step(STEPS)
    end

    # Remove step multiple_dwellings_relief if there is no MDR is selected as part of non ads reliefs
    # @param next_steps [Array] Array of wizard step page names
    # @return [Array] Array of wizard steps by removing the mdr step
    def remove_mdr_step(next_steps)
      next_steps_dup = next_steps.dup
      next_steps_dup.delete('multiple_dwellings_relief') if @lbtt_return.md_relief.empty?
      next_steps_dup
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of ReliefClaim class that has attributes with value.
    def new_list_item_relief_claims
      Lbtt::ReliefClaim.new(lbtt_return_ads_due: @lbtt_return.show_ads?, lbtt_return_flbt_type: @lbtt_return.flbt_type)
    end

    # Return the parameter list filtered for the attributes of the LbttReturn model
    def filter_params(sub_object_attribute = nil)
      if sub_object_attribute == :md_relief
        params.require(:returns_lbtt_relief_claim).permit(Lbtt::ReliefClaim.attribute_list)
      else
        return {} unless params[:returns_lbtt_lbtt_return] # may have no reliefs

        permitted_attributes = Lbtt::ReliefClaim.attribute_list + [:relief_type_expanded]
        # Allow the relief claims but reject them as the relief claims are handled as part of the later list processing
        params.require(:returns_lbtt_lbtt_return).permit(returns_lbtt_relief_claim: permitted_attributes)
              .except(:returns_lbtt_relief_claim)
      end
    end

    # Return the parameter list filtered for the attributes in list_attribute
    def filter_list_params(_list_attribute, _sub_object_attribute = nil)
      return unless params[:returns_lbtt_lbtt_return] && params[:returns_lbtt_lbtt_return][:returns_lbtt_relief_claim]

      permitted_attributes = [:relief_type_expanded] + Lbtt::ReliefClaim.attribute_list
      params.require(:returns_lbtt_lbtt_return)
            .permit(returns_lbtt_relief_claim: permitted_attributes)[:returns_lbtt_relief_claim].values
    end
  end
end
