# frozen_string_literal: true

# Authorisation helpers for this application
module AuthorisationHelper
  # Constants for the various authorisation checks

  # SLFT
  # View SLFT Summary, and the Create SLFT button
  SLFT_SUMMARY = %i[pwslftsb pwslftam pwslftup pwslftcr].freeze
  # Final Submit on SLFT
  SLFT_SUBMIT = %i[pwslftsb pwslftam].freeze
  # Amend link on return lists for SLFT (summary page and view all returns)
  SLFT_AMEND = %i[pwslftam].freeze
  # Continue link on return lists for SLFT (summary page and view all returns)
  SLFT_CONTINUE = %i[pwslftup].freeze
  # Delete link on return lists for SLFT (summary page and view all returns)
  SLFT_DELETE = %i[pwslftdl].freeze
  # Save button on SLFT summary page
  SLFT_SAVE = %i[pwslftcr pwslftup].freeze
  # Access to Load SLFT 'page'
  SLFT_LOAD = %i[pwslftam pwslftup].freeze

  # LBTT
  # View LBTT Summary, and the Create LBTT button
  LBTT_SUMMARY = %i[pwlbttsb pwlbttam pwlbttup pwlbttcr].freeze
  # Final Submit on LBTT
  LBTT_SUBMIT = %i[pwlbttsb pwlbttam].freeze
  # Amend link on return lists for LBTT (summary page and view all returns)
  LBTT_AMEND = %i[pwlbttam].freeze
  # Continue link on return lists for LBTT (summary page and view all returns)
  LBTT_CONTINUE = %i[pwlbttup].freeze
  # Delete link on return lists for LBTT (summary page and view all returns)
  LBTT_DELETE = %i[pwlbttdl].freeze
  # Save button on LBTT summary page
  LBTT_SAVE = %i[pwlbttcr or pwlbttup].freeze
  # Access to Load LBTT 'page'
  LBTT_LOAD = %i[pwlbttam or pwslbttup].freeze

  # Messages/Dashboard
  # View all returns page and link/Returns region on the dashboard page
  VIEW_RETURNS = %i[tareview].freeze
  # View all message page and link/unread message region on the dashboard page
  VIEW_MESSAGES = %i[wssecmsg].freeze
  # Show/view link on messages (summary page and view)
  VIEW_MESSAGE_DETAIL = %i[wsmsgdtl].freeze
  # Create Message on dashboard/Reply to message show message page
  CREATE_MESSAGE = %i[wssmcre].freeze
  # Create an attachment on a message
  CREATE_ATTACHMENT = %i[wssmatt].freeze
  # Download attachment on show message page
  DOWNLOAD_ATTACHMENT = %i[wsgetatt].freeze
  # Delete attachment link on post submission page for messages
  DELETE_ATTACHMENT = %i[wssmdet].freeze
  # Dashboard home page (and minimum set of actions required to access application)
  DASHBOARD_HOME = %i[racpvw tareview wsgetatt wssecmsg wsprtdtl wslsttra wsmsgdtl wslstusr].freeze

  # Accounts/Users
  # Account Details link and  Page
  VIEW_ACCOUNTS = %i[wsprtdtl].freeze
  # Update Party links and pages
  UPDATE_PARTY = %i[wsmntpty].freeze
  # Edit and create a new user links and pages from Account users page
  CREATE_USERS = %i[usrupd].freeze

  # Claim Repayment
  CLAIM_REPAYMENT = %i[wsclaim].freeze

  # Claim Repayment attachment
  CLAIM_REPAYMENT_ATTACHMENT = %i[wsadddoc].freeze

  # download Receipt pdf
  DOWNLOAD_RECEIPT = %i[wsrecpdf].freeze

  # download Return pdf WSVWRPDF
  DOWNLOAD_RETURN_PDF = %i[wsvwrpdf].freeze
end
