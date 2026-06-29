import 'package:flutter/material.dart';
import 'flagforge_sdk.dart';

void main() {
  runApp(const ECommerceApp());
}

class ECommerceApp extends StatelessWidget {
  final bool useLiveConnection;
  const ECommerceApp({super.key, this.useLiveConnection = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studio Essentials',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF000000)),
          titleTextStyle: TextStyle(
            color: Color(0xFF000000),
            fontFamily: 'SpaceGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF000000),
          secondary: Color(0xFF757575),
          surface: Color(0xFFF6F6F6),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF000000),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF000000),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF757575),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontFamily: 'SpaceGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          secondary: Color(0xFF9E9E9E),
          surface: Color(0xFF161616),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      home: ECommerceDashboard(useLiveConnection: useLiveConnection),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final IconData icon;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.icon,
  });
}

class ECommerceDashboard extends StatefulWidget {
  final String? welcomeMessage;
  final bool? showSpecialOffer;
  final bool? showChatbot;
  final bool useLiveConnection;

  const ECommerceDashboard({
    super.key,
    this.welcomeMessage,
    this.showSpecialOffer,
    this.showChatbot,
    this.useLiveConnection = true,
  });

  @override
  State<ECommerceDashboard> createState() => _ECommerceDashboardState();
}

class _ECommerceDashboardState extends State<ECommerceDashboard> {
  // Local state mapping
  late String welcomeMessage;
  late bool showSpecialOffer;
  late bool showChatbot;
  
  String _selectedUserId = '45';
  String? _selectedGroup;

  late final FlagForgeClient _client;

  @override
  void initState() {
    super.initState();
    welcomeMessage = widget.welcomeMessage ?? "Welcome to our shop!";
    showSpecialOffer = widget.showSpecialOffer ?? false;
    showChatbot = widget.showChatbot ?? false;

    // Stream listener and state dispatcher initialization
    _client = FlagForgeClient();
    _client.userId = _selectedUserId;
    _client.group = _selectedGroup;
    _client.addListener(() {
      if (!mounted) return;

      // 1. Map welcome_message configurations
      final newWelcome = _client.getConfigValue('welcome_message');
      if (newWelcome != null) {
        setState(() {
          welcomeMessage = newWelcome.toString();
        });
      }

      // 2. Map show_special_offer flags
      setState(() {
        showSpecialOffer = _client.isEnabled('show_special_offer');
      });

      // 3. Map ai_recommendations or enable_chatbot flags
      setState(() {
        showChatbot = _client.isEnabled('ai_recommendations') || _client.isEnabled('enable_chatbot');
      });
    });

    // Wire and begin WebSocket/REST hydration with Project 3
    if (widget.useLiveConnection) {
      _client.initialize(3);
    }
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  // Static mock items
  static const List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Studio Headset Mono',
      category: 'Electronics',
      price: 299.00,
      description: 'Active noise cancelling wireless headset. Pure sound, architectural geometry.',
      icon: Icons.headphones_outlined,
    ),
    Product(
      id: 'p2',
      name: 'Minimalist Commuter Pack',
      category: 'Clothing',
      price: 149.00,
      description: 'Water-resistant rolltop bag with modular compartments and custom aluminum hardware.',
      icon: Icons.backpack_outlined,
    ),
    Product(
      id: 'p3',
      name: 'Mechanical Keyboard 60%',
      category: 'Electronics',
      price: 189.00,
      description: 'Tactile hot-swappable mechanical switches with solid anodized chassis.',
      icon: Icons.keyboard_outlined,
    ),
    Product(
      id: 'p4',
      name: 'Anodized Desk Lamp',
      category: 'Living',
      price: 89.00,
      description: 'Dimmable warm LED fixture constructed from sandblasted aluminum components.',
      icon: Icons.light_outlined,
    ),
  ];

  final Set<String> _cart = {};
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF282828) : const Color(0xFFE2E2E2);
    final cardBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    // Filter items based on selected category
    final filteredProducts = _selectedCategory == 'All'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('STUDIO ESSENTIALS'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                onPressed: () => _showCartDialog(context),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal Divider
            Container(height: 1, color: borderColor),

            // Greeting Widget
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                welcomeMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.search, size: 20, color: Colors.grey),
                    ),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search catalog...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['All', 'Electronics', 'Clothing', 'Living'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : borderColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (showSpecialOffer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF0055), Color(0xFFFF5500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'SPECIAL OFFER: Use code ESSENTIALS20 for 20% off!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Catalog grid feed
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final isInCart = _cart.contains(product.id);

                  return GestureDetector(
                    onTap: () => _showProductDetails(context, product),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        border: Border.all(color: borderColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Graphic Frame box representing product image
                          Expanded(
                            flex: 4,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  topRight: Radius.circular(7),
                                ),
                              ),
                              child: Hero(
                                tag: 'product-icon-${product.id}',
                                child: Icon(
                                  product.icon,
                                  size: 44,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ),
                          // Content Info
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        product.category.toUpperCase(),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          letterSpacing: 1.0,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isInCart) {
                                              _cart.remove(product.id);
                                            } else {
                                              _cart.add(product.id);
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isInCart
                                                ? (isDark ? Colors.white24 : Colors.black12)
                                                : (isDark ? Colors.white : Colors.black),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isInCart ? Icons.check : Icons.add,
                                            size: 14,
                                            color: isInCart
                                                ? (isDark ? Colors.white : Colors.black)
                                                : (isDark ? Colors.black : Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIMULATE USER PERSONA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPersonaChip('Regular User (ID: 45)', '45', null, borderColor, isDark),
                _buildPersonaChip('Beta Tester (Group: beta, ID: 88)', '88', 'beta', borderColor, isDark),
                _buildPersonaChip('Random Out-of-Bracket User (ID: 99)', '99', null, borderColor, isDark),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: showChatbot
          ? FloatingActionButton(
              onPressed: () => _showChatbotDialog(context),
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              child: const Icon(Icons.chat_bubble_outline),
            )
          : null,
    );
  }

  Widget _buildPersonaChip(String label, String userId, String? group, Color borderColor, bool isDark) {
    final isSelected = _selectedUserId == userId && _selectedGroup == group;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedUserId = userId;
            _selectedGroup = group;
          });
          if (widget.useLiveConnection) {
            _client.updateContext(userId, group, 3);
          }
        }
      },
      selectedColor: isDark ? Colors.white : Colors.black,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : borderColor,
          width: 1,
        ),
      ),
    );
  }

  void _showChatbotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? const Color(0xFF282828) : const Color(0xFFE2E2E2),
            ),
          ),
          title: const Text(
            'SHOP ASSISTANT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          content: const Text('Hello! How can I assist you with your order today?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CLOSE',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
        final accentColor = isDark ? Colors.white : Colors.black;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isInCart = _cart.contains(product.id);

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: sheetBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(128),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Hero(
                              tag: 'product-icon-${product.id}',
                              child: Icon(
                                product.icon,
                                size: 80,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            product.category.toUpperCase(),
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isInCart) {
                            _cart.remove(product.id);
                          } else {
                            _cart.add(product.id);
                          }
                        });
                        setModalState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isInCart ? 'REMOVE FROM CART' : 'ADD TO CART',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cartProducts = _products.where((p) => _cart.contains(p.id)).toList();

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? const Color(0xFF282828) : const Color(0xFFE2E2E2),
            ),
          ),
          title: const Text(
            'SHOPPING BAG',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          content: cartProducts.isEmpty
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Your shopping bag is empty.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cartProducts.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final product = cartProducts[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () {
                              setState(() {
                                _cart.remove(product.id);
                              });
                              Navigator.of(context).pop();
                              _showCartDialog(context);
                            },
                          )
                        ],
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CLOSE',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (cartProducts.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _cart.clear();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checkout successful! bag cleared.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('CHECKOUT'),
              ),
          ],
        );
      },
    );
  }
}
