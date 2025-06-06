// import 'package:flutter/material.dart';
// import 'package:aifinanceapp/screens/home_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;
//   final Color _primaryColor = const Color.fromARGB(255, 48, 98, 206);
//   final Color _secondaryColor = const Color.fromARGB(255, 74, 92, 214);

//   // User data
//   String _name = '';
//   String _expenseType = '';
//   String _walletName = 'Daily Expense';
//   String _currency = 'USD';
//   final List<String> _selectedCategories = [];
//   final List<String> _selectedIncomeSources = [];

//   final List<String> _expenseTypes = [
//     'Budgeting for personal finances',
//     'Managing business expenses',
//     'Tracking travel expenses',
//     'Recurring bills & subscriptions',
//     'Savings & investments',
//     'Credit card repayment',
//     'Debt payments (loans, mortgage, etc.)',
//     'Shared expenses',
//   ];

//   final List<String> _expenseCategories = [
//     'Food & Drinks',
//     'Shopping',
//     'Transportation',
//     'Entertainment',
//     'Health',
//     'Grocery',
//     'Pet',
//     'Education',
//     'Electronics',
//     'Beauty',
//     'Sports',
//   ];

//   final List<String> _incomeSources = [
//     'Salary',
//     'Investment',
//     'Bonus',
//     'Business',
//   ];

//   final List<String> _currencies = [
//     'USD',
//     'EUR',
//     'GBP',
//     'INR',
//     'JPY',
//     'CAD',
//     'AUD',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Progress indicator
//             LinearProgressIndicator(
//               value: (_currentPage + 1) / 4,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
//               minHeight: 4,
//             ),
            
//             // Logo
//             Padding(
//               padding: const EdgeInsets.only(top: 40, bottom: 20),
//               child: Image.asset(
//                 'assets/images/ai_logo.webp',
//                 height: 100,
//               ),
//             ),
            
//             // Page content
//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 physics: const NeverScrollableScrollPhysics(),
//                 onPageChanged: (index) {
//                   setState(() {
//                     _currentPage = index;
//                   });
//                 },
//                 children: [
//                   // Page 1: Name
//                   _buildNamePage(),
                  
//                   // Page 2: Expense Type
//                   _buildExpenseTypePage(),
                  
//                   // Page 3: Wallet Name & Currency
//                   _buildWalletSetupPage(),
                  
//                   // Page 4: Categories
//                   _buildCategoriesPage(),
//                 ],
//               ),
//             ),
            
//             // Navigation buttons
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Row(
//                 children: [
//                   if (_currentPage > 0)
//                     TextButton(
//                       onPressed: () {
//                         _pageController.previousPage(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                         );
//                       },
//                       child: Text(
//                         'Back',
//                         style: TextStyle(color: _primaryColor),
//                       ),
//                     ),
//                   const Spacer(),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (_currentPage < 3) {
//                         _pageController.nextPage(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                         );
//                       } else {
//                         // Finish onboarding
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(builder: (_) => const HomeScreen()),
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _primaryColor,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 32, vertical: 12),
//                     ),
//                     child: Text(
//                       _currentPage == 3 ? 'Finish' : 'Continue',
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNamePage() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Welcome! Let\'s get you set up!',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: _primaryColor,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'First, tell me what is your name.',
//             style: TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 32),
//           TextField(
//             onChanged: (value) => _name = value,
//             decoration: InputDecoration(
//               hintText: 'Enter your name',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: _primaryColor),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: _primaryColor, width: 2),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExpenseTypePage() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'What type of expenses do you want to track?',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: _primaryColor,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _expenseTypes.length,
//               itemBuilder: (context, index) {
//                 final type = _expenseTypes[index];
//                 return Card(
//                   elevation: _expenseType == type ? 4 : 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: BorderSide(
//                       color: _expenseType == type ? _primaryColor : Colors.grey[300]!,
//                       width: _expenseType == type ? 2 : 1,
//                     ),
//                   ),
//                   child: ListTile(
//                     title: Text(type),
//                     onTap: () {
//                       setState(() {
//                         _expenseType = type;
//                       });
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWalletSetupPage() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Now let\'s set up your wallet!',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: _primaryColor,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Give a name for your wallet, like "Daily Expense"',
//             style: TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 24),
//           TextField(
//             onChanged: (value) => _walletName = value,
//             decoration: InputDecoration(
//               labelText: 'Wallet name',
//               hintText: 'Daily Expense',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: _primaryColor),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: _primaryColor, width: 2),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           DropdownButtonFormField<String>(
//             value: _currency,
//             decoration: InputDecoration(
//               labelText: 'Select your currency',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: _primaryColor),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: _primaryColor, width: 2),
//               ),
//             ),
//             items: _currencies.map((String currency) {
//               return DropdownMenuItem<String>(
//                 value: currency,
//                 child: Text(currency),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 _currency = value!;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoriesPage() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Pick categories or create custom ones',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: _primaryColor,
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Expense suggestions',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: _expenseCategories.map((category) {
//               final isSelected = _selectedCategories.contains(category);
//               return FilterChip(
//                 label: Text(category),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   setState(() {
//                     if (selected) {
//                       _selectedCategories.add(category);
//                     } else {
//                       _selectedCategories.remove(category);
//                     }
//                   });
//                 },
//                 selectedColor: _secondaryColor,
//                 checkmarkColor: Colors.white,
//                 labelStyle: TextStyle(
//                   color: isSelected ? Colors.white : Colors.black,
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 8),
//           TextButton(
//             onPressed: () {
//               // TODO: Implement custom category addition
//             },
//             child: const Text('+ Add new'),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Income suggestions',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: _incomeSources.map((source) {
//               final isSelected = _selectedIncomeSources.contains(source);
//               return FilterChip(
//                 label: Text(source),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   setState(() {
//                     if (selected) {
//                       _selectedIncomeSources.add(source);
//                     } else {
//                       _selectedIncomeSources.remove(source);
//                     }
//                   });
//                 },
//                 selectedColor: _secondaryColor,
//                 checkmarkColor: Colors.white,
//                 labelStyle: TextStyle(
//                   color: isSelected ? Colors.white : Colors.black,
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:aifinanceapp/screens/home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Color _primaryColor = const Color.fromARGB(255, 48, 98, 206);
  final Color _secondaryColor = const Color.fromARGB(255, 74, 92, 214);

  // User data
  String _name = '';
  String _expenseType = '';
  String _walletName = 'Daily Expense';
  String _currency = 'USD';
  final List<String> _selectedCategories = [];
  final List<String> _selectedIncomeSources = [];

  final List<String> _expenseTypes = [
    'Budgeting for personal finances',
    'Managing business expenses',
    'Tracking travel expenses',
    'Recurring bills & subscriptions',
    'Savings & investments',
    'Credit card repayment',
    'Debt payments (loans, mortgage, etc.)',
    'Shared expenses',
  ];

  final Map<String, IconData> _expenseCategories = {
    'Food & Drinks': Icons.restaurant,
    'Shopping': Icons.shopping_bag,
    'Transportation': Icons.directions_car,
    'Entertainment': Icons.movie,
    'Health': Icons.health_and_safety,
    'Grocery': Icons.shopping_cart,
    'Pet': Icons.pets,
    'Education': Icons.school,
    'Electronics': Icons.devices,
    'Beauty': Icons.face_retouching_natural,
    'Sports': Icons.sports_soccer,
  };

  final Map<String, IconData> _incomeSources = {
    'Salary': Icons.work,
    'Investment': Icons.trending_up,
    'Bonus': Icons.monetization_on,
    'Business': Icons.business,
  };

  final Map<String, String> _currencies = {
    'USD': 'United States Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'KRW': 'South Korean Won',
    'MXN': 'Mexican Peso',
    'SGD': 'Singapore Dollar',
    'CHF': 'Swiss Franc',
    'NZD': 'New Zealand Dollar',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'ZAR': 'South African Rand',
    'HKD': 'Hong Kong Dollar',
    'TRY': 'Turkish Lira',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht',
    'PHP': 'Philippine Peso',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              minHeight: 4,
            ),
            
            // Logo
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Image.asset(
                'assets/images/ai_logo.webp',
                height: 100,
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Page 1: Name
                  _buildNamePage(),
                  
                  // Page 2: Expense Type
                  _buildExpenseTypePage(),
                  
                  // Page 3: Wallet Name & Currency
                  _buildWalletSetupPage(),
                  
                  // Page 4: Categories
                  _buildCategoriesPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Back',
                        style: TextStyle(color: _primaryColor),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Finish onboarding
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      _currentPage == 3 ? 'Finish' : 'Continue',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome! Let\'s get you set up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'First, tell me what is your name.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: (value) => _name = value,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTypePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of expenses do you want to track?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _expenseTypes.length,
              itemBuilder: (context, index) {
                final type = _expenseTypes[index];
                return Card(
                  elevation: _expenseType == type ? 4 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _expenseType == type ? _primaryColor : Colors.grey[300]!,
                      width: _expenseType == type ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(type),
                    onTap: () {
                      setState(() {
                        _expenseType = type;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSetupPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now let\'s set up your wallet!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Give a name for your wallet, like "Daily Expense"',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) => _walletName = value,
            decoration: InputDecoration(
              labelText: 'Wallet name',
              hintText: 'Daily Expense',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select your currency',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200, // Fixed height to prevent overflow
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              child: ListView.builder(
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final currencyCode = _currencies.keys.elementAt(index);
                  final currencyName = _currencies[currencyCode];
                  return ListTile(
                    title: Text('$currencyCode - $currencyName'),
                    leading: Radio<String>(
                      value: currencyCode,
                      groupValue: _currency,
                      onChanged: (value) {
                        setState(() {
                          _currency = value!;
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                    onTap: () {
                      setState(() {
                        _currency = currencyCode;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick categories or create custom ones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Expense suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _expenseCategories.entries.map((entry) {
                final category = entry.key;
                final icon = entry.value;
                final isSelected = _selectedCategories.contains(category);
                return InputChip(
                  label: Text(category),
                  avatar: Icon(icon, color: _primaryColor),
                  selected: isSelected,                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                  selectedColor: Colors.grey[200], // Light grey when selected
                  checkmarkColor: _primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _showAddCustomCategoryDialog(context, isIncome: false);
              },
              child: const Text('+ Add new'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Income suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _incomeSources.entries.map((entry) {
                final source = entry.key;
                final icon = entry.value;
                final isSelected = _selectedIncomeSources.contains(source);
                return InputChip(
                  label: Text(source),
                  avatar: Icon(icon, color: _primaryColor),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIncomeSources.add(source);
                      } else {
                        _selectedIncomeSources.remove(source);
                      }
                    });
                  },
                  selectedColor: Colors.grey[200], // Light grey when selected
                  checkmarkColor: _primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.black,
                  ),
                );
              }).toList(),
            ),
            TextButton(
              onPressed: () {
                _showAddCustomCategoryDialog(context, isIncome: true);
              },
              child: const Text('+ Add new'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddCustomCategoryDialog(BuildContext context, {required bool isIncome}) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New ${isIncome ? 'Income Source' : 'Category'}'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter ${isIncome ? 'income source' : 'category'} name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    if (isIncome) {
                      _incomeSources[controller.text] = Icons.add;
                      _selectedIncomeSources.add(controller.text);
                    } else {
                      _expenseCategories[controller.text] = Icons.add;
                      _selectedCategories.add(controller.text);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}