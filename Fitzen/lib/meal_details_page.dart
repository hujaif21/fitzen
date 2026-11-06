import 'package:flutter/material.dart';

class MealDetailsPage extends StatefulWidget {
  const MealDetailsPage({super.key});

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  int portionSize = 1;

  final Color primaryRed = const Color(0xFFC62828);
  final Color teal = const Color(0xFF087A7A);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealImage(),

                    _buildMealTitle(),

                    _buildMacros(),

                    _buildFiber(),

                    _buildPortionSize(),

                    _buildIngredients(),

                    _buildPreparation(),

                    _buildTip(),

                    _buildButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),

      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F8),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0E9E7),
            width: 0.8,
          ),
        ),
      ),

      child: Row(
        children: [

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
              size: 25,
            ),
          ),

          const SizedBox(width: 18),

          // LOGO
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: Color(0xFFC62828),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 7),

          const Expanded(
            child: Text(
              'FitZen',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Icon(
            Icons.calendar_today_outlined,
            size: 21,
            color: Color(0xFF5B3E39),
          ),

          const SizedBox(width: 17),

          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFC62828),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEAL IMAGE
  // ============================================================

  Widget _buildMealImage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),

        child: Stack(
          children: [

            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFFE7E2DF),

              child: Image.network(
                'https://images.unsplash.com/photo-1512621776951-a57141f2eefd'
                    '?auto=format&fit=crop&w=900&q=80',

                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 60,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

            // PLANT POWERED
            Positioned(
              left: 10,
              top: 10,
              child: _smallBadge(
                icon: Icons.eco_outlined,
                text: 'Plant Powered',
                color: Colors.green,
              ),
            ),

            // BOOKMARK
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark_border,
                  color: primaryRed,
                ),
              ),
            ),

            // BOTTOM BADGES
            Positioned(
              left: 10,
              bottom: 10,
              child: Row(
                children: [
                  _imageBadge(
                    Icons.eco_outlined,
                    'High Protein',
                    Colors.green,
                  ),

                  const SizedBox(width: 6),

                  _imageBadge(
                    Icons.add_circle_outline,
                    'Gluten-Free',
                    Colors.orange,
                  ),

                  const SizedBox(width: 6),

                  _imageBadge(
                    Icons.access_time,
                    '20 Mins',
                    primaryRed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEAL TITLE
  // ============================================================

  Widget _buildMealTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Expanded(
                child: Text(
                  'Grilled Paneer & Quinoa Salad',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Container(
                width: 35,
                height: 35,
                decoration: const BoxDecoration(
                  color: Color(0xFFB8FAF7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFF087A7A),
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          const Text(
            '580 kcal  •  Large Bowl (~380g)',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFC62828),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Charred marinated paneer cubes on a bed of fluffy '
                'quinoa, crisp baby spinach, cucumber, cherry tomatoes, '
                'and lemon-herb tahini drizzle.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF6F625F),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MACROS
  // ============================================================

  Widget _buildMacros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),

      child: Row(
        children: [

          Expanded(
            child: _macroCard(
              title: 'Protein',
              value: '32',
              unit: 'g',
              percentage: '35% daily goal',
              color: const Color(0xFFC91D2B),
              progress: 0.35,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _macroCard(
              title: 'Carbs',
              value: '60',
              unit: 'g',
              percentage: '27% daily goal',
              color: const Color(0xFF087A7A),
              progress: 0.27,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _macroCard(
              title: 'Fats',
              value: '22',
              unit: 'g',
              percentage: '34% daily goal',
              color: const Color(0xFF0FA36B),
              progress: 0.34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard({
    required String title,
    required String value,
    required String unit,
    required String percentage,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFF0E9E7),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF594C49),
                  ),
                ),
              ),

              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF594C49),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE7E4E3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            percentage,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF8A7E7A),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIBER
  // ============================================================

  Widget _buildFiber() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 8, 15, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF0E9E7),
        ),
      ),

      child: Row(
        children: [

          const Icon(
            Icons.eco_outlined,
            size: 17,
            color: Color(0xFF087A47),
          ),

          const SizedBox(width: 7),

          const Expanded(
            child: Text(
              'Dietary Fiber',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          const Text(
            '11 g (44% RDI)',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PORTION SIZE
  // ============================================================

  Widget _buildPortionSize() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF0E9E7),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portion Size',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Text(
                      '1.0 Serving (~380g)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              _portionButton(
                icon: Icons.remove,
                onTap: () {
                  if (portionSize > 1) {
                    setState(() {
                      portionSize--;
                    });
                  }
                },
              ),

              const SizedBox(width: 12),

              Text(
                '$portionSize.0',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 12),

              _portionButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    portionSize++;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 9),

          const Row(
            children: [
              Icon(
                Icons.tune,
                size: 13,
                color: Color(0xFF087A7A),
              ),

              SizedBox(width: 5),

              Expanded(
                child: Text(
                  'Ingredients and nutritional calculations adjust automatically.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _portionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 30,
        height: 30,

        decoration: const BoxDecoration(
          color: Color(0xFFF5F2F1),
          shape: BoxShape.circle,
        ),

        child: Icon(
          icon,
          size: 17,
        ),
      ),
    );
  }

  // ============================================================
  // INGREDIENTS
  // ============================================================

  Widget _buildIngredients() {
    final ingredients = [
      ['Fresh Low-Fat Paneer', '150g'],
      ['Tri-Color Quinoa', '75g'],
      ['Baby Spinach & Arugula', '50g'],
      ['Cherry Tomatoes', '6 pcs'],
      ['Crisp Cucumber', '1/2'],
      ['Cold-Pressed Dressing', '1 tbsp'],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              const Text(
                'Required Ingredients',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '6 items',
                  style: TextStyle(
                    fontSize: 9,
                  ),
                ),
              ),

              const Spacer(),

              const Text(
                'Select All',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF087A7A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ...ingredients.map(
                (ingredient) => _ingredientItem(
              ingredient[0],
              ingredient[1],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientItem(
      String name,
      String quantity,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF0E9E7),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 19,
            height: 19,

            decoration: BoxDecoration(
              color: const Color(0xFFE8E5E4),
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          Text(
            quantity,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREPARATION
  // ============================================================

  Widget _buildPreparation() {
    final steps = [
      [
        'Fluff the Quinoa',
        'Rinse quinoa thoroughly. Simmer in 150ml water over low heat for 12 minutes until fluffy. Remove lid and let cool to room temperature.',
      ],
      [
        'Sear the Paneer',
        'Lightly season paneer cubes with cumin, smoked paprika and sea salt. Sear in a non-stick pan over medium-high heat for 4 minutes until golden.',
      ],
      [
        'Assemble the Base',
        'Layer fresh greens, cucumber slices and halved tomatoes in a wide bowl. Top with cooled quinoa and warm charred paneer cubes.',
      ],
      [
        'Dress and Savor',
        'Drizzle olive oil and lemon dressing evenly across the bowl. Garnish with microgreens or cracked black pepper.',
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Text(
                'Step-by-Step Preparation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              const Text(
                '4 quick steps',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ...List.generate(
            steps.length,
                (index) => _stepItem(
              index + 1,
              steps[index][0],
              steps[index][1],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(
      int number,
      String title,
      String description,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFF0E9E7),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 27,
            height: 27,

            decoration: const BoxDecoration(
              color: Color(0xFF6DE7E7),
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF087A7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: Color(0xFF706562),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIP
  // ============================================================

  Widget _buildTip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 8, 15, 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF087A47),
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Color(0xFF6A5D59),
                  fontSize: 10.5,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Prep tip: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E3532),
                    ),
                  ),
                  TextSpan(
                    text:
                    'Soak paneer cubes in warm water for 5 minutes '
                        'before searing for a cloud-soft interior with a '
                        'crispy crust.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),

      child: Column(
        children: [

          SizedBox(
            width: double.infinity,
            height: 48,

            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Meal logged successfully!',
                    ),
                  ),
                );
              },

              icon: const Icon(
                Icons.restaurant,
                size: 18,
              ),

              label: const Text(
                'Log this Meal (580 kcal)  →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 46,

            child: OutlinedButton.icon(
              onPressed: () {},

              icon: const Icon(
                Icons.swap_horiz,
                size: 18,
                color: Color(0xFF087A7A),
              ),

              label: const Text(
                'Swap with Alternative Meal',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                ),
              ),

              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL BADGES
  // ============================================================

  Widget _smallBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),

          const SizedBox(width: 4),

          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageBadge(
      IconData icon,
      String text,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),

          const SizedBox(width: 3),

          Text(
            text,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}