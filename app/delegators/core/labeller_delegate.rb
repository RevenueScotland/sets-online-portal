# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Provides support to label a field for hint text, label
  # if is initialised with the class and then provides methods to the containing class that can obtain a label or
  # hint text
  class LabellerDelegate
    # Regex that identifies if text is an english question
    QUESTION_REGEX = /\A((ARE |DO |DOES |HAS |HAVE |HOW |IF |IS |SHOULD |WHAT |WHICH |WHO |WILL ))/i

    # @param klass_or_model [Object] The class or model that requires labelling functionality
    # @param method [Symbol] The name of the method that requires labelling functionality
    # @param action_name [Symbol] The current action name (view) being rendered use to change
    #   the labels and hints for specific pages
    # @param optional [Boolean] Is the field optional, adds the optional tag on the label
    # @param interpolations [Hash] Hash of options that are passed down to the translations, they are
    #   passed to both hint and label so the same argument name can be used in both, if you want
    #   different ones then use different argument names
    def initialize(klass_or_model:, method:, action_name: nil, optional: false, interpolations: {})
      @action_name = action_name
      @optional = optional
      @interpolations = interpolations
      @label_visually_hidden = false
      set_klass_and_method(klass_or_model, method)
    end

    # Returns the label text for a given field, the label text can be modified based on the action name in use
    # This routine will default to the normal text based on the :attribute key
    # However, if you want to augment the label on the page e.g. with visually hidden tags you can provide a
    # separate label key path, and interpolate the label into it
    # @example with the label interpolated
    #   en:
    #     activerecord:
    #       attributes:
    #         my_model:
    #           my_method: "My Method"
    #
    #   en:
    #     activerecord:
    #       labels:
    #         my_model:
    #           my_method: "%{label}<span class=\"visually hidden\"> is great <\span>"
    #
    # The above generates a label on the page of "My Method<span class="visually hidden"> is great <\span>"
    # The messages and other output will use the base attribute label of "My Method"
    #
    # @example with no interpolation
    #   en:
    #     activerecord:
    #       attributes:
    #         my_model:
    #           my_method: "My method"
    #
    #   en:
    #     activerecord:
    #       labels:
    #         my_model:
    #           my_method: "Your method"
    #
    # The above generates a label on the page of "Your method"
    # The messages and other output will use the base attribute label of "My method"
    #
    # The label text is normally found on the path
    # <locale>.<activerecord|activemodel>.labels.<model>.<method>
    # This can either be a string or contain records for each view, in which case you can provide a default
    # value
    # @example where the label changes per view
    #   en:
    #     activerecord:
    #       labels:
    #         my_model:
    #           my_method:
    #             new: This is the hint for a new record using the standard resourceful methods
    #             edit: This is the hint for updating this field
    #             default: This is the default hint
    # @return [String] the label text
    def label_text
      return @label_text if @label_text

      derive_label_and_visually_hidden
      @label_text
    end

    # A label can have visually hidden components, or can be completely visually hidden
    # To make a label completely visually hidden then position it under a visually hidden key
    #
    # @example
    #   en:
    #     activerecord:
    #       labels:
    #         my_model:
    #           my_method:
    #             visually_hidden: "Your method"
    # @return [Boolean] Is the label to be visually hidden
    def label_visually_hidden
      return @label_visually_hidden if @label_visually_hidden

      derive_label_and_visually_hidden
      @label_visually_hidden
    end

    # Returns the hint text for a given field, the hint text can be modified based on the action name in use
    # The hint text is normally found on the path
    # <locale>.<activerecord|activemodel>.hints.<model>.<method>
    # This can either be a string or contain records for each view, in which case you can provide a default
    # value
    # @example just one value
    #   en:
    #     activerecord:
    #       hints:
    #         my_model:
    #           my_method: This is the hint text
    # @example where the hint changes per view
    #   en:
    #     activerecord:
    #       hints:
    #         my_model:
    #           my_method:
    #             new: This is the hint for a new record using the standard resourceful methods
    #             edit: This is the hint for updating this field
    #             default: This is the default hint
    # @return [String] the hint text
    def hint_text
      @hint_text ||= get_text(:hints, interpolations: @interpolations, default: '')
    end

    private

    # Derives and memoizes the label and if it is visually hidden
    def derive_label_and_visually_hidden
      @label_visually_hidden = false
      base_label = @klass.human_attribute_name(@method.to_s)
      augmented_interpolations = @interpolations.merge(label: base_label)
      @label_text = get_text(:labels, interpolations: augmented_interpolations, default: base_label)
      if @label_text.is_a?(Hash)
        # This means text potentially visually hidden
        @label_text = text_from_hash(@label_text, :visually_hidden, augmented_interpolations)
        @label_visually_hidden = true
      end
      @label_text += '?'.html_safe if @label_text.match(QUESTION_REGEX)
      @label_text = "#{@label_text} (#{I18n.t('optional')})" if @optional
    end

    # Returns the text from the translation files (:hint or :label), if necessary deals with
    # a hash entry
    # @param type [Symbol] The type :hint or :label
    # @param interpolations [Hash] The interpolations to be used. this may have been augmented by the calling
    #   routine
    # @return [String] the text from the translations
    def get_text(type, interpolations: {}, default: nil)
      text = I18n.t(@method, default: default, scope: [i18n_scope(@klass), type, @klass.model_name.i18n_key],
                             **interpolations)
      text = text_from_hash(text, @action_name, interpolations) if text.is_a?(Hash)
      # Explicitly mark the translation as safe so we can include html
      (text.is_a?(Hash) ? text : text.html_safe) # rubocop:disable Rails/OutputSafety
    end

    # Extracts the actual hint text based on the page from the hash, and if necessary applies
    # interpolations
    # @param hash [Hash] The array of translations
    # @param hash_key [Symbol] The action_name being used OR :visually_hidden
    # @param interpolations [String] The array of interpolations
    # @return [String|Hash] The string found or the hash if no key found
    def text_from_hash(hash, hash_key, interpolations)
      # If the hash contains the visually_hidden key, the action_name call
      # doesn't find it so return the hash itself for the next iteration
      text = (hash.key?(hash_key) ? hash[hash_key] : hash[:default]) || hash
      (text.is_a?(Hash) ? text : I18n.interpolate(text, interpolations))
    end

    # Sets the klass and method depending on an model or klass is provided
    def set_klass_and_method(klass_or_model, method)
      @method = method
      if klass_or_model.instance_of?(Class)
        @klass = klass_or_model
      else
        @klass = klass_or_model.class
        @method = klass_or_model.translation_attribute(method) if klass_or_model.respond_to?(:translation_attribute)
      end
    end

    # if model doesn't respond to scope then use :activerecord
    # @param klass [Class] The class for which we need the label
    def i18n_scope(klass)
      # :nocov:
      (klass.respond_to?(:i18n_scope) ? klass.i18n_scope : :activerecord)
      # :nocov:
    end
  end
end
