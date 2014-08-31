# encoding: utf-8

BLACKJACK = 21
DEALER_HIT_UNTIL = 17
INITIAL_POT_SIZE = 500

helpers do
  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end

  def csrf_metatag
    Rack::Csrf.csrf_metatag(env)
  end

  def hand_value(cards)
    values = cards.map { |value| value[1] }

    total = 0
    values.each do |value|
      if value == 'A'
        total += 11
      else
        total += value.to_i == 0 ? 10 : value.to_i
      end
    end

    # correct for aces
    values.select { |value| value == 'A' }.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def display_card(card)
    suite = case card[0]
            when 'C' then 'clubs'
            when 'D' then 'diamonds'
            when 'H' then 'hearts'
            when 'S' then 'spades'
            end

    value = card[1]
    if %w(J Q K A).include? value
      value = case card[1]
              when 'J' then 'jack'
              when 'Q' then 'queen'
              when 'K' then 'king'
              when 'A' then 'ace'
              end
    end
    "<img src=\"/images/cards/#{suite}_#{value}.jpg\" class=\"card_image\">"
  end

  def winner!(msg)
    @show_player_buttons = false
    @show_play_again_buttons = true
    session[:player_pot] += session[:player_bet]
    @winner = "<strong>#{session[:player_name]} wins $#{session[:player_bet]}!</strong> #{msg}"
  end

  def loser!(msg)
    @show_player_buttons = false
    @show_play_again_buttons = true
    session[:player_pot] -= session[:player_bet]
    @loser = "<strong>#{session[:player_name]} loses $#{session[:player_bet]}.</strong> #{msg}"
  end

  def tie!(msg)
    @show_player_buttons = false
    @show_play_again_buttons = true
    @winner = "<strong>It's a tie!</strong> #{msg}"
  end
end

before do
  @show_player_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = 'Name is required.'
    halt erb(:new_player)
  end

  session[:player_name] = Rack::Utils.escape_html params[:player_name]
  session[:player_pot] = INITIAL_POT_SIZE
  redirect '/bet'
end

get '/game' do
  session[:turn] = 'player'
  session[:allow_dealer_hit] = false

  suites = %w(C D H S)
  values = %w(2 3 4 5 6 7 8 9 10 J Q K A)
  session[:deck] = suites.product(values).shuffle!

  session[:player_hand] = []
  session[:dealer_hand] = []

  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop

  if hand_value(session[:player_hand]) >= BLACKJACK
    session[:turn] = 'game_over'
    redirect '/game/compare'
  end
  erb :game
end

# Player actions

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  if hand_value(session[:player_hand]) >= BLACKJACK
    session[:turn] = 'game_over'
    redirect '/game/compare'
  end

  erb :game, layout: false
end

post '/game/player/stand' do
  session[:turn] = 'dealer'
  redirect '/game/dealer'
end

get '/game/dealer' do
  halt 403, 'Unexpected request' unless session[:turn] == 'dealer'
  @show_player_buttons = false
  total = hand_value(session[:dealer_hand])

  if total >= DEALER_HIT_UNTIL
    session[:turn] = 'game_over'
    redirect '/game/compare' 
  end

  # dealer hit
  session[:allow_dealer_hit] = true
  @show_dealer_hit_button = true

  erb :game, layout: false
end

post '/game/dealer/hit' do
  halt 403, 'Unexpected request' unless session[:allow_dealer_hit] == true
  session[:dealer_hand] << session[:deck].pop
  session[:allow_dealer_hit] = false
  redirect '/game/dealer'
end

get '/game/compare' do
  halt 403, 'Unexpected request' unless session[:turn] == 'game_over'
  @show_player_buttons = false
  player_total = hand_value(session[:player_hand])
  dealer_total = hand_value(session[:dealer_hand])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}")
  end

  erb :game, layout: false
end

get '/game/over' do
  if session[:player_pot] == 0
    @error = "#{session[:player_name]} ran out of money. Better luck next time."
  else
    @success = "#{session[:player_name]} walked away with $#{session[:player_pot]}."
  end
  erb :game_over
end

get '/bet' do
  session[:player_bet] = nil
  redirect '/game/over' if session[:player_pot] == 0
  erb :bet
end

post '/bet' do
  if params[:bet].to_i <= 0 || params[:bet].to_i > session[:player_pot]
    @error = "Invalid bet. Choose a range between $1 and $#{session[:player_pot]}."
    halt erb(:bet)
  end
  session[:player_bet] = params[:bet].to_i

  redirect '/game'
end
