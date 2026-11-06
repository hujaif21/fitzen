import 'package:flutter/material.dart';
import 'core_settings.dart'; // Handles Dark Mode & theme colors

class DietSuggestionsScreen extends StatefulWidget {
  const DietSuggestionsScreen({super.key});

  @override
  State<DietSuggestionsScreen> createState() => _DietSuggestionsScreenState();
}

class _DietSuggestionsScreenState extends State<DietSuggestionsScreen> {
  // 0 = Gain Weight, 1 = Lose Weight
  int _selectedGoalTab = 0;
  // 0 = Breakfast, 1 = Lunch, 2 = Snacks, 3 = Dinner
  int _selectedMealTab = 0;
  // true = Vegetarian, false = Non-Vegetarian
  bool _isVegetarian = true;

  // Scroll controllers for horizontal arrow buttons in Breakfast & Lunch
  final ScrollController _scrollController = ScrollController();

  void _scrollList(double offset) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Master Database: High Protein, High Fiber, Indian & Easy-to-make focus
  final Map<String, Map<String, Map<String, List<Map<String, String>>>>> _masterDietData = {
    'gain': {
      'breakfast': {
        'veg': [
          {'name': 'Paneer Bhurji with Whole Wheat Roti', 'calories': '450 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Peanut Butter & Banana Multigrain Toast', 'calories': '400 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Besan Cheela stuffed with Paneer', 'calories': '380 kcal', 'protein': '20g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Oats & Banana Smoothie with Peanut Butter', 'calories': '500 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Moong Dal chilla with Green Chutney', 'calories': '360 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Aloo Poha with Roasted Peanuts & Peas', 'calories': '350 kcal', 'protein': '8g Protein', 'image': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400'},
          {'name': 'Full-Fat Greek Yogurt with Granola & Chia', 'calories': '420 kcal', 'protein': '15g Protein', 'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400'},
          {'name': 'Stuffed Methi Paratha with White Butter', 'calories': '480 kcal', 'protein': '10g Protein', 'image': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400'},
          {'name': 'Sprouted Mung Bean Salad Bowl', 'calories': '310 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Sada Dosa with Peanut & Chana Dal Chutney', 'calories': '410 kcal', 'protein': '11g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
        ],
        'nonveg': [
          {'name': 'Whole Eggs Masala Omelette with Toast', 'calories': '460 kcal', 'protein': '28g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Chicken Keema Stuffed Paratha with Curd', 'calories': '550 kcal', 'protein': '32g Protein', 'image': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400'},
          {'name': 'Scrambled Eggs on Avocado Multigrain Toast', 'calories': '450 kcal', 'protein': '24g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Boiled Eggs with Peanut Butter Toast', 'calories': '420 kcal', 'protein': '25g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Chicken Sausage & Egg Breakfast Platter', 'calories': '530 kcal', 'protein': '34g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Smoked Salmon & Cream Cheese Bagel', 'calories': '440 kcal', 'protein': '26g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Egg Bhurji with Butter Pav', 'calories': '430 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Turkey Bacon & Egg White Sandwich', 'calories': '390 kcal', 'protein': '29g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Protein Pancake Stack with Egg Whites & Honey', 'calories': '450 kcal', 'protein': '30g Protein', 'image': 'https://images.unsplash.com/photo-1517673136205-aeb1964a7967?w=400'},
          {'name': 'Shredded Chicken Sandwich with Green Chutney', 'calories': '410 kcal', 'protein': '31g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
        ],
      },
      'lunch': {
        'veg': [
          {'name': 'Rajma Masala with High-Fiber Brown Rice', 'calories': '520 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Soya Chunks Curry with Whole Wheat Roti', 'calories': '460 kcal', 'protein': '32g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Chole (Chickpea) with Jeera Quinoa', 'calories': '540 kcal', 'protein': '19g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Palak Paneer with Multigrain Roti & Dal', 'calories': '580 kcal', 'protein': '26g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Mixed Dal Tadka with Steamed Rice & Salad', 'calories': '480 kcal', 'protein': '17g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Kadhi Pakora with High-Fiber Brown Rice', 'calories': '490 kcal', 'protein': '13g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Stuffed Capsicum with Paneer & Sprouts', 'calories': '430 kcal', 'protein': '21g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Mushroom Matar Masala with Butter Roti', 'calories': '450 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Black Eyed Pea (Lobia) Curry with Roti', 'calories': '470 kcal', 'protein': '20g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Sprouted Moong Dal Khichdi with Ghee', 'calories': '440 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
        ],
        'nonveg': [
          {'name': 'Grilled Chicken Breast with Brown Rice & Dal', 'calories': '520 kcal', 'protein': '45g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Chicken Biryani with Boiled Egg & Raita', 'calories': '650 kcal', 'protein': '38g Protein', 'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400'},
          {'name': 'Fish Curry (Surstrommen/Rohu) with Rice', 'calories': '490 kcal', 'protein': '34g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Egg Curry with 3 Chapatis & Salad', 'calories': '480 kcal', 'protein': '26g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Mutton Rogan Josh with Garlic Naan', 'calories': '700 kcal', 'protein': '40g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Butter Chicken with Whole Wheat Roti', 'calories': '620 kcal', 'protein': '39g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Prawn Masala with Steamed Basmati Rice', 'calories': '480 kcal', 'protein': '32g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Lean Beef Steak with Sweet Potato Mash', 'calories': '620 kcal', 'protein': '44g Protein', 'image': 'https://images.unsplash.com/photo-1558030006-450675393462?w=400'},
          {'name': 'Chicken Fried Rice loaded with Egg & Veggies', 'calories': '590 kcal', 'protein': '40g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Tuna Salad Sandwich with Whole Grain Bread', 'calories': '450 kcal', 'protein': '35g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
        ],
      },
      'snacks': {
        'veg': [
          {'name': 'Roasted Makhana (Fox Nuts) in Ghee', 'calories': '220 kcal', 'protein': '6g Protein', 'image': 'https://images.unsplash.com/photo-1599599810694-b5b37262c5b1?w=400'},
          {'name': 'Sprouted Moong & Chana Chaat with Lemon', 'calories': '250 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Paneer Tikka Cubes with Mint Chutney', 'calories': '310 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Mixed Dry Fruits, Cashews & Walnuts', 'calories': '350 kcal', 'protein': '10g Protein', 'image': 'https://images.unsplash.com/photo-1599599810694-b5b37262c5b1?w=400'},
          {'name': 'Peanut Butter Banana Smoothie', 'calories': '380 kcal', 'protein': '11g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Boiled Sweet Potato Chaat with Masala', 'calories': '230 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1577805947697-89e18249d767?w=400'},
          {'name': 'Roasted Chana (Black Chickpeas) Snack', 'calories': '200 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1599599810694-b5b37262c5b1?w=400'},
          {'name': 'Cheese Corn Sandwich on Brown Bread', 'calories': '340 kcal', 'protein': '10g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Steamed Corn Chat with Lemon & Butter', 'calories': '210 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Vegetable Oats Cutlets with Chutney', 'calories': '280 kcal', 'protein': '8g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
        ],
        'nonveg': [
          {'name': 'Chicken Tikka Skewers with Mint Dip', 'calories': '310 kcal', 'protein': '32g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Hard-Boiled Eggs with Pepper & Salt', 'calories': '210 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Chicken Sandwich with Mayo & Cheese', 'calories': '410 kcal', 'protein': '28g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Tuna Salad on Whole Wheat Crackers', 'calories': '320 kcal', 'protein': '24g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Egg Bhurji Pav (1 Pav)', 'calories': '360 kcal', 'protein': '20g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Grilled Prawn Skewers with Garlic Herb', 'calories': '250 kcal', 'protein': '25g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Chicken Seekh Kebab Roll', 'calories': '380 kcal', 'protein': '26g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Turkey & Cheese Pinwheels', 'calories': '340 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400'},
          {'name': 'Chicken Meatballs with BBQ Dip', 'calories': '350 kcal', 'protein': '27g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Smoked Salmon Dip with Cucumber Slices', 'calories': '280 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
        ],
      },
      'dinner': {
        'veg': [
          {'name': 'Shahi Paneer with Butter Naan & Salad', 'calories': '600 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Dal Palak with Jeera Rice & Roti', 'calories': '510 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Malai Kofta with Phulkas', 'calories': '580 kcal', 'protein': '15g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Aloo Gobi with Stuffed Paratha', 'calories': '490 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400'},
          {'name': 'Vegetable Biryani with Boondi Raita', 'calories': '520 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400'},
          {'name': 'Kaju Curry with Steamed Rice', 'calories': '610 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Soya Matar Masala with Chapati', 'calories': '470 kcal', 'protein': '28g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Stuffed Baingan (Eggplant) with Roti', 'calories': '440 kcal', 'protein': '10g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Mixed Dal Tadka with Steamed Rice', 'calories': '480 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Cheese Pasta with White Sauce & Garlic Bread', 'calories': '630 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400'},
        ],
        'nonveg': [
          {'name': 'Chicken Tikka Masala with Butter Naan', 'calories': '650 kcal', 'protein': '42g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Mutton Bhuna Masala with Roti', 'calories': '680 kcal', 'protein': '40g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Chicken Korma with Roomali Roti', 'calories': '620 kcal', 'protein': '39g Protein', 'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400'},
          {'name': 'Garlic Butter Prawns with Spaghetti', 'calories': '540 kcal', 'protein': '36g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Goan Fish Curry with Steamed Rice', 'calories': '560 kcal', 'protein': '34g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Baked Salmon with Garlic Herb Butter & Rice', 'calories': '580 kcal', 'protein': '38g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Egg Masala Gravy with 3 Chapatis', 'calories': '490 kcal', 'protein': '28g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Roast Turkey Breast with Potatoes', 'calories': '530 kcal', 'protein': '45g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Pepper Steak with Mushroom Sauce', 'calories': '640 kcal', 'protein': '46g Protein', 'image': 'https://images.unsplash.com/photo-1558030006-450675393462?w=400'},
          {'name': 'Chicken Fried Rice with Manchurian', 'calories': '600 kcal', 'protein': '38g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
        ],
      },
    },
    'lose': {
      'breakfast': {
        'veg': [
          {'name': 'Moong Dal Chilla (High Protein Pancake)', 'calories': '180 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Masala Oats with Mixed Veggies', 'calories': '190 kcal', 'protein': '6g Protein', 'image': 'https://images.unsplash.com/photo-1517673136205-aeb1964a7967?w=400'},
          {'name': 'Sprouted Mung Bean & Cucumber Chaat', 'calories': '140 kcal', 'protein': '9g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Steamed Idli with Tomato Chutney & Sambar', 'calories': '160 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Green Smoothie (Spinach, Apple, Lemon)', 'calories': '110 kcal', 'protein': '3g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Poha with Green Peas & Lemon Juice', 'calories': '210 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400'},
          {'name': 'Chia Seed Pudding with Almond Milk', 'calories': '180 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400'},
          {'name': 'Ragi Malt (Healthy Fiber Porridge Drink)', 'calories': '170 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Vegetable Dalia (Broken Wheat Khichdi)', 'calories': '200 kcal', 'protein': '6g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Skimmed Milk with Roasted Makhana', 'calories': '150 kcal', 'protein': '8g Protein', 'image': 'https://images.unsplash.com/photo-1599599810694-b5b37262c5b1?w=400'},
        ],
        'nonveg': [
          {'name': 'Boiled Egg Whites with Spinach Salad', 'calories': '130 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Egg White Omelette with Mushrooms & Peppers', 'calories': '150 kcal', 'protein': '20g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Smoked Salmon Slice with Cucumber Slices', 'calories': '170 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Chicken Broth with Poached Egg White', 'calories': '140 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Avocado Toast with 1 Poached Egg', 'calories': '240 kcal', 'protein': '9g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Tuna and Lettuce Boat Wraps', 'calories': '180 kcal', 'protein': '25g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Greek Yogurt with Shredded Chicken Salad', 'calories': '210 kcal', 'protein': '24g Protein', 'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400'},
          {'name': 'Turkey Breast Slice Roll with Greens', 'calories': '160 kcal', 'protein': '19g Protein', 'image': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400'},
          {'name': 'Boiled Eggs in Tomato Salsa', 'calories': '190 kcal', 'protein': '15g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Protein Coffee with Collagen & Egg Whites', 'calories': '130 kcal', 'protein': '20g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
        ],
      },
      'lunch': {
        'veg': [
          {'name': 'Moong Dal Soup with Steamed Quinoa', 'calories': '240 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Tofu Stir-Fry with Broccoli & Bell Peppers', 'calories': '220 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Mixed Vegetable Salad with Lemon Dressing', 'calories': '130 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400'},
          {'name': 'Lauki (Bottle Gourd) Soup with 1 Roti', 'calories': '180 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Palak Soup with Roasted Chana', 'calories': '190 kcal', 'protein': '10g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Low-Oil Grilled Paneer Salad', 'calories': '260 kcal', 'protein': '17g Protein', 'image': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400'},
          {'name': 'Cabbage & Peas Sabzi with 1 Multi-Grain Roti', 'calories': '210 kcal', 'protein': '6g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Boiled Rajma Salad with Onions & Tomatoes', 'calories': '230 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Steamed Sprouts and Cucumber Bowl', 'calories': '160 kcal', 'protein': '11g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Zucchini Noodles with Tomato Basil Sauce', 'calories': '150 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400'},
        ],
        'nonveg': [
          {'name': 'Grilled Chicken Salad with Olive Oil Dressing', 'calories': '280 kcal', 'protein': '35g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Baked Cod Fish with Asparagus & Lemon', 'calories': '220 kcal', 'protein': '30g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Lemon Herb Chicken Breast with Zucchini', 'calories': '250 kcal', 'protein': '38g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Clear Chicken Soup with Shredded Veggies', 'calories': '160 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Grilled Prawns with Garlic Herb Salad', 'calories': '200 kcal', 'protein': '27g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Turkey Breast Slice Bowl with Mixed Greens', 'calories': '210 kcal', 'protein': '30g Protein', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400'},
          {'name': 'Steamed Salmon with Dill and Cucumber', 'calories': '310 kcal', 'protein': '34g Protein', 'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400'},
          {'name': 'Boiled Eggs and Tuna Salad Bowl', 'calories': '270 kcal', 'protein': '33g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Lean Ground Turkey Lettuce Cups', 'calories': '240 kcal', 'protein': '29g Protein', 'image': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400'},
          {'name': 'Tandoori Chicken Tikka (Without Oil) & Salad', 'calories': '290 kcal', 'protein': '39g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
        ],
      },
      'snacks': {
        'veg': [
          {'name': 'Roasted Makhana (Fox Nuts) with Salt & Pepper', 'calories': '120 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1599599810694-b5b37262c5b1?w=400'},
          {'name': 'Cucumber & Carrot Sticks with Hummus', 'calories': '130 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Green Tea with 3 Roasted Almonds', 'calories': '30 kcal', 'protein': '1g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Boiled Corn Chat with Lemon & Chat Masala', 'calories': '140 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Buttermilk (Chaas) with Roasted Cumin', 'calories': '50 kcal', 'protein': '3g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Clear Tomato Soup', 'calories': '60 kcal', 'protein': '2g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Roasted Chana (Black Chickpeas)', 'calories': '150 kcal', 'protein': '9g Protein', 'image': 'https://images.unsplash.com/photo-1599599810694-b5b37262c5b1?w=400'},
          {'name': 'Sliced Papaya Bowl', 'calories': '90 kcal', 'protein': '1g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
          {'name': 'Lemon Water with Chia Seeds', 'calories': '35 kcal', 'protein': '1g Protein', 'image': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400'},
          {'name': 'Steamed Edamame with Sea Salt', 'calories': '160 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'},
        ],
        'nonveg': [
          {'name': 'Boiled Egg White with Black Pepper', 'calories': '85 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400'},
          {'name': 'Clear Chicken Broth Cup', 'calories': '70 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Sliced Cucumber with Tuna Flakes', 'calories': '110 kcal', 'protein': '15g Protein', 'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400'},
          {'name': 'Grilled Chicken Tikka Skewer (1 pc)', 'calories': '120 kcal', 'protein': '18g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Shrimp Salad Bites on Cucumber Rounds', 'calories': '95 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Turkey Jerky (Low Sodium)', 'calories': '100 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400'},
          {'name': 'Bone Broth with Herbs', 'calories': '60 kcal', 'protein': '11g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Steamed Crab Meat Salad Cups', 'calories': '115 kcal', 'protein': '14g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Smoked Salmon Roll-Up with Cream Cheese', 'calories': '130 kcal', 'protein': '13g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Grilled Chicken Breast Slice with Mustard', 'calories': '105 kcal', 'protein': '20g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
        ],
      },
      'dinner': {
        'veg': [
          {'name': 'Lauki (Bottle Gourd) Sabzi with 1 Roti', 'calories': '210 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Moong Dal Khichdi with Mixed Veggies', 'calories': '250 kcal', 'protein': '9g Protein', 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400'},
          {'name': 'Mixed Vegetable Soup with Tofu Cubes', 'calories': '190 kcal', 'protein': '11g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Spinach & Tomato Clear Soup', 'calories': '90 kcal', 'protein': '4g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Steamed Broccoli & Paneer Salad', 'calories': '270 kcal', 'protein': '16g Protein', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400'},
          {'name': 'Stir-Fried Mushroom & Bell Peppers', 'calories': '180 kcal', 'protein': '7g Protein', 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'},
          {'name': 'Methi (Fenugreek) Leaves Soup & Salad', 'calories': '130 kcal', 'protein': '6g Protein', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400'},
          {'name': 'Zucchini & Lentil Stew', 'calories': '220 kcal', 'protein': '12g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Baked Sweet Potato with Curd Dip', 'calories': '240 kcal', 'protein': '5g Protein', 'image': 'https://images.unsplash.com/photo-1577805947697-89e18249d767?w=400'},
          {'name': 'Clear Cabbage Soup with Black Pepper', 'calories': '80 kcal', 'protein': '3g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
        ],
        'nonveg': [
          {'name': 'Grilled Chicken Breast with Steamed Asparagus', 'calories': '290 kcal', 'protein': '40g Protein', 'image': 'https://images.unsplash.com/photo-1604908176997-125f2596f37c?w=400'},
          {'name': 'Baked White Fish with Lemon and Herbs', 'calories': '230 kcal', 'protein': '32g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Chicken & Mushroom Clear Broth Stew', 'calories': '210 kcal', 'protein': '29g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Steamed Salmon with Spinach Salad', 'calories': '320 kcal', 'protein': '35g Protein', 'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400'},
          {'name': 'Prawn and Lettuce Stir-Fry', 'calories': '200 kcal', 'protein': '28g Protein', 'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400'},
          {'name': 'Turkey Meatball & Zucchini Noodle Soup', 'calories': '260 kcal', 'protein': '31g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Boiled Egg Whites & Tomato Basil Soup', 'calories': '180 kcal', 'protein': '22g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Grilled Tilapia Fish with Green Beans', 'calories': '240 kcal', 'protein': '33g Protein', 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400'},
          {'name': 'Chicken Soup with Shredded Cabbage', 'calories': '195 kcal', 'protein': '27g Protein', 'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400'},
          {'name': 'Lean Beef Broth with Mixed Greens', 'calories': '280 kcal', 'protein': '36g Protein', 'image': 'https://images.unsplash.com/photo-1558030006-450675393462?w=400'},
        ],
      },
    }
  };

  List<Map<String, String>> get _currentList {
    String goalKey = _selectedGoalTab == 0 ? 'gain' : 'lose';
    String mealKey = ['breakfast', 'lunch', 'snacks', 'dinner'][_selectedMealTab];
    String dietKey = _isVegetarian ? 'veg' : 'nonveg';

    return _masterDietData[goalKey]?[mealKey]?[dietKey] ?? [];
  }

  // Define Elegant Premium Gradients for specific Goals
  List<Color> get _goalGradient => _selectedGoalTab == 0
      ? const [Color(0xFFFF8A3D), Color(0xFFF97316)] // Warm Sunset for Bulking
      : const [Color(0xFF2DD4BF), Color(0xFF0D9488)]; // Ocean Teal for Cutting

  Color get _goalAccent => _selectedGoalTab == 0 ? const Color(0xFFFF8A3D) : const Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> items = _currentList;

    return FitzenScreen(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
        title: Text(
          'Diet & Meal Suggestions',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 1. HERO BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                  child: _buildHeroBanner(items.length),
                ),

                const SizedBox(height: 12),

                // 2. GOAL TABS (Gain Weight vs Lose Weight)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGoalButton(
                          title: 'Gain Weight',
                          index: 0,
                          activeGradient: const [Color(0xFFFF8A3D), Color(0xFFF97316)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGoalButton(
                          title: 'Lose Weight',
                          index: 1,
                          activeGradient: const [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. MEAL TIME SELECTOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                        color: AppColors.textSecondary(context),
                        onPressed: () => _scrollList(-160),
                        splashRadius: 20,
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ListView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            children: [
                              _buildMealTab('☕ Breakfast', 0),
                              const SizedBox(width: 10),
                              _buildMealTab('🍲 Lunch', 1),
                              const SizedBox(width: 10),
                              _buildMealTab('🍎 Snacks', 2),
                              const SizedBox(width: 10),
                              _buildMealTab('🍽️ Dinner', 3),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                        color: AppColors.textSecondary(context),
                        onPressed: () => _scrollList(160),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. VEG / NON-VEG TOGGLE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border(context), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDietTypeButton(
                            title: '🌱 Vegetarian',
                            isActive: _isVegetarian,
                            activeColor: const Color(0xFF10B981), // Premium Emerald
                            onTap: () => setState(() => _isVegetarian = true),
                          ),
                        ),
                        Expanded(
                          child: _buildDietTypeButton(
                            title: '🍗 Non-Veg',
                            isActive: !_isVegetarian,
                            activeColor: const Color(0xFFF43F5E), // Premium Rose/Red
                            onTap: () => setState(() => _isVegetarian = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // 5. FOOD LIST
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final Map<String, String> food = items[index];
                  final int step = index > 8 ? 8 : index;

                  return TweenAnimationBuilder<double>(
                    key: ValueKey('${food['name']}-$_selectedGoalTab-$_selectedMealTab'),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 350 + (step * 70)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          // FIX: Proper math syntax for translating offset
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildFoodCard(food),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _buildHeroBanner(int count) {
    final bool isGain = _selectedGoalTab == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _goalGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: _goalAccent.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGain ? 'Bulking Fuel' : 'Cutting Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isGain
                      ? 'Calorie-dense, protein-rich meals to build muscle mass.'
                      : 'Light, high-fiber, high-protein meals to stay lean.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '$count curated recipes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                isGain ? '💪' : '🥗',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalButton({required String title, required int index, required List<Color> activeGradient}) {
    final bool isSelected = _selectedGoalTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedGoalTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: activeGradient) : null,
          color: isSelected ? null : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border(context),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: activeGradient[1].withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: -0.2,
            fontFamily: 'Poppins',
            color: isSelected ? Colors.white : AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTab(String title, int index) {
    final bool isSelected = _selectedMealTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedMealTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.card(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.border(context),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primaryAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFamily: 'Poppins',
              color: isSelected ? Colors.white : AppColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDietTypeButton({required String title, required bool isActive, required Color activeColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            fontFamily: 'Poppins',
            color: isActive ? activeColor : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, String> food) {
    // Beautiful subtle accent colors for the food type
    final Color dietColor = _isVegetarian ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context), width: 1.2),
        boxShadow: [
          // Soft ambient shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  food['image']!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 96,
                      height: 96,
                      color: AppColors.border(context),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _goalAccent,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 96,
                    height: 96,
                    color: AppColors.border(context),
                    child: Icon(Icons.restaurant_rounded, color: AppColors.textSecondary(context)),
                  ),
                ),
              ),

              // Premium Veg / Non-Veg Indicator Dot
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: dietColor, width: 1.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dietColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _badge(food['calories']!, Icons.local_fire_department_rounded, const Color(0xFFFF8A3D)), // Orange for calories
                    _badge(food['protein']!, Icons.fitness_center_rounded, const Color(0xFF0EA5E9)), // Blue for protein
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}