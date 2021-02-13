class AdvanceCopyPresenter < BasePresenter
  FOOT_NOTE_REG = /<sup foot_note=\d+>(\d+)<\/sup>/

  def cache_key(action_name:)
    "#{current_locale}-advance_copy:#{action_name}-#{chapter_with_range}-#{fetch_approved_translations.join('-')}"
  end

  def translations
    ResourceContent.where(id: fetch_approved_translations)
  end

  def current_verse
    Verse.where(chapter_id: chapter_id, verse_number: params[:from]).first
  end

  def verses_to_copy
    @verses = Verse.order('verses.verse_number asc')
                  .where(chapter_id: chapter_id)
                  .where("verses.verse_number >= ? AND verses.verse_number <= ?", params[:from], params[:to])

    if (fetch_approved_translations.present?)
      @verses = @verses
                    .where(translations: {resource_content_id: fetch_approved_translations})
                    .eager_load(:translations)
                    .order('translations.priority ASC')
    end

    @verses
  end

  def format_translation_text(translation)
    text = translation.text

    if include_footnote?
      text = text.gsub(FOOT_NOTE_REG) do
        "[#{Regexp.last_match(1)}]"
      end
    else
      text = text.gsub(FOOT_NOTE_REG, '')
    end

    text.strip
  end

  def format_footnote_text(footnote)
    TAG_SANITIZER.sanitize(footnote.text, tags: [], attributes: []).strip
  end

  def include_footnote?
    strong_memoize :footnote do
      'yes' == params[:footnote]
    end
  end

  def include_arabic?
    strong_memoize :arabic do
      'yes' == params[:arabic]
    end
  end

  def range
    strong_memoize :ayah_range do
      if params[:range].present?
        params[:range].split('-').map(&:to_i)
      else
        [params[:from].to_i]
      end
    end
  end

  def chapter_with_range
    "#{chapter_id}-#{range}-#{params[:from]}-#{include_footnote?}-#{include_arabic?}"
  end

  def chapter_id
    params[:chapter_id]
  end

  def fetch_approved_translations
    strong_memoize :approve_translations do
      valid_translations(store_result: false)
    end
  end
end