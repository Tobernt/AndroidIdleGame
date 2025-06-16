import 'package:flutter/material.dart';
import '../../services/purchase_service.dart';
import '../../core/game_manager.dart';

class PurchaseScreen extends StatefulWidget {
  final GameManager gameManager;

  const PurchaseScreen({super.key, required this.gameManager});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late final PurchaseService _purchaseService;
  bool _purchased = false;

  @override
  void initState() {
    super.initState();
    _purchased = widget.gameManager.state.metaValues['permanent_gold_bonus'] == true;
    _purchaseService = PurchaseService(onPurchase: _onPurchased);
    _purchaseService.init();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  void _onPurchased() {
    widget.gameManager.state.metaValues['permanent_gold_bonus'] = true;
    setState(() => _purchased = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank You!'),
        content: const Text('Thanks for supporting. Enjoy the permanent 2× bonus!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Support Us'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: _purchased
            ? const Text('2× Bonus Active')
            : ElevatedButton(
                onPressed: () {
                  _purchaseService.buyPermanentBonus();
                },
                child: const Text('Buy Permanent 2× Bonus \$2.99'),
              ),
      ),
    );
  }
}
