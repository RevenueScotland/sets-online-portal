# frozen_string_literal: true

# override the refresh so it doesn't run during the tests otherwise
ReferenceData::ReferenceValue.refresh_cache!
ReferenceData::SystemParameter.refresh_cache!
ReferenceData::PwsText.refresh_cache!
ReferenceData::TaxReliefType.refresh_cache!
ReferenceData::SystemNotice.refresh_cache!
