import 'dart:developer';

import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_back.jpg', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.0, 0.8],
              ),
            ),
          ),
          Positioned(
            top: 40,
            bottom: -60,
            left: 0, // Margem da esquerda
            right: 0,
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFDFBB19)),
                borderRadius: BorderRadius.all(Radius.circular(40)),
                color: Colors.transparent,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Column(
                children: [
                  Positioned(
                    top: 400.h,
                    left: 0,
                    right: 0,
                    child: Text(
                      "Find my",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ).apply(color: Colors.white),
                    ),
                  ),
                  Text(
                    "Barber",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ).apply(color: Colors.white),
                  ),
                  Text(
                    "Find a barber close to and book at your convenience",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ).apply(color: Colors.white),
                  ),
                  const SizedBox(height: 50),
                  ButtonWid(),
                  const SizedBox(height: 60), // Margem inferior
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ButtonWid extends StatelessWidget {
  const ButtonWid({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        log("sla");
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 450.w,
        height: 80.h,
        decoration: BoxDecoration(
          color: Color(0xFFDFBB19),
          borderRadius: BorderRadius.all(Radius.circular(40)),
        ),
        child: Center(
          child: Text(
            "Sign up",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ).apply(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
