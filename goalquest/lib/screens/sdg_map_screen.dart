import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SdgMapScreen extends StatelessWidget {
  const SdgMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SDG Map'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Interactice gloabe coming soon\n(Tap SDGs below to explore)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a Goal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 17,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, idx) {
                final sdgNumber = idx + 1;
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/learnSdg',
                      arguments: sdgNumber,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black12,
                        )
                      ],
                    ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          child: Text('$sdgNumber'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SDG $sdgNumber',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}