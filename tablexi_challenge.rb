require 'open-uri'

class Menu

  class ListItem
    attr_accessor :menu_entry

    def initialize(menu_entry)
      @menu_entry = menu_entry.split(",")
    end

    def title
      @menu_entry.first
    end

    def price_in_cents
      (@menu_entry.last.delete("$").to_f * 100).to_i
    end

  end

  attr_accessor :total, :total_price, :all_prices, :titles_by_price, :minimum_item_count, :maximum_item_count

  def initialize(menu_file)
    file = menu_file
    @total = file.each_line.first
    @total_price = (total.delete("$").to_f * 100).to_i
    menu_list_items = file.each_line.map {|x| ListItem.new(x)}
    @all_prices = menu_list_items.map {|x| x.price_in_cents }
    most_expensive_item = all_prices.sort.last
    least_expensive_item = all_prices.sort.first
    @minimum_item_count = (total_price / most_expensive_item).floor
    @maximum_item_count = (total_price / least_expensive_item).ceil
    @titles_by_price = Hash[menu_list_items.map{|item| [item.price_in_cents, item.title]}]
  end

  def prices_with_duplicates
    array = []
    all_prices.each { |price| (maximum_quantity_of(price)).times { array << price } }
    array
  end

  def maximum_quantity_of(item_price)
    (total_price / item_price).floor.to_i
  end

  def all_combinations
    possible_item_quantities = (minimum_item_count..maximum_item_count).to_a
    combinations = []
    possible_item_quantities.each do |quantity|
      prices_with_duplicates.combination(quantity).each do |combination|
        combinations << combination if combination.inject(0, &:+) == total_price
      end
    end
    combinations.uniq
  end

  def combination_hash
    combo_hash = {};
    all_combinations.each_with_index do |combo, index|
      combo_hash[index + 1] = combo.map {|price| titles_by_price[price]}
    end
    combo_hash
  end

  def parsed_result_for(combination)
    unique_items = combination.uniq
    itemized_list = unique_items.map {|item| "#{combination.count(item)}x #{item}"}
    itemized_list.join(", ")
  end

  def output_results(results)
    results.each { |key, value| puts "Combo #{key}: #{parsed_result_for(value)}" }
  end

  def get_combinations
    results = combination_hash
    if total_price == 0
      puts "Money can't buy you love, but you do need it to buy food. Since you have $0, you can't buy anything!"
    elsif results.empty?
      puts "Sorry, no combinations match that total!"
    else
      puts "Good work, there are #{results.length} combination(s) for #{total}"
      output_results(results)
    end
  end

end

puts "Enter the path to your menu file:"

Menu.new(open(gets.chomp)).get_combinations
