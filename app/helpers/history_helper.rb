module HistoryHelper

  def card_stats_additions(result, player)
    return {} if result.card_history_list.empty?
    {
      class: %w[dotted-baseline card-history-button],
      data: {
        :'content-path' => card_stats_profile_history_path(result, player: player),
        title: "Card history",
        trigger: 'hover'
      }
    }
  end

  def timeline_additions(result)
    return {} if result.card_history_list.empty?
    header = escape_once(render(partial: 'timeline_header', locals: { result: result }))
    {
      class: %w[btn btn-default btn-xs timeline-button],
      data: {
        :'content-path' => timeline_profile_history_path(result),
        title: header,
        trigger: 'click'
      }
    }
  end

  def hero_label(hero_name, label: hero_name, additions: {})
    additions[:class] ||= []
    additions[:class] << 'hero-label'
    [
      hero_icon(hero_name),
      content_tag(:span, label, additions)
    ].join(' ').html_safe
  end

  def player_label_for_result(result, additions: {})
    case
    when result.arena? || !current_user.deck_tracking?
      hero_label(result.hero.titleize, additions: additions)
    when result.deck
      label_for_deck(result.deck, additions: additions)
    else
      hero_label(result.hero.titleize, label: "Other #{result.hero.titleize}", additions: additions)
    end
  end

  def opponent_label_for_result(result, additions: {})
    case
    when result.arena? || !current_user.deck_tracking?
      hero_label(result.opponent.titleize, additions: additions)
    when result.opponent_deck
      label_for_deck(result.opponent_deck, additions: additions)
    else
      hero_label(result.opponent.titleize, label: "Other #{result.opponent.titleize}", additions: additions)
    end
  end

  def label_for_deck(deck, additions: {})
    return hero_label(deck.hero.titleize, additions: additions) unless current_user.deck_tracking?
    hero_label(deck.hero.titleize, label: deck.full_name, additions: additions)
  end

  def hero_icon(name)
    content_tag(:span, '', class: ["#{name.downcase}-icon", 'hero-icon'])
  end

  def match_duration(secs)
    pluralize((secs / 60.0).ceil, "minute")
  end

  private

  def group_card_histories_by_card_and_sort_by_mana(card_histories)
    card_histories.group_by { |e| CARDS[e[:card_id]] }.sort_by { |card, _| card.mana || -1 }
  end

  def group_card_histories_chronologically(card_histories)
    groups = []

    current_card_group = []
    current_player = nil
    current_turn = nil

    card_histories.each do |card_history|
      if (current_player && current_player != card_history[:player]) || (current_turn && card_history[:turn] != current_turn)
        groups << current_card_group
        current_card_group = []
      end
      current_player = card_history[:player]
      current_turn = card_history[:turn]
      current_card_group << card_history
    end

    if current_card_group.any?
      groups << current_card_group
    end

    groups
  end

  def deck_edit(result, type, field)
    eligible_decks = @decks.select { |d| d.hero == result.send(type) }
    return if result.arena? || eligible_decks.empty? || !current_user.deck_tracking?
    blank_name = "Other #{result.send(type).titleize}"

    [
      form_for([:profile, result], html: { class: %w[deck-edit-form hidden] }) do |f|
        f.collection_select field, eligible_decks, :id, :full_name, { include_blank: blank_name, selected: result.send(field) }
      end,
      icon('pencil', class: 'deck-edit-button')
    ].join.html_safe
  end

end
