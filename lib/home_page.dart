import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:payment_intrigation/keys.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  double amount = 2000;
  Map<String, dynamic>? intentPaymentData;

  showPaymentSheet() async {
          print('in showPaymentSheet');

    try {
      await Stripe.instance.presentPaymentSheet().then((val) {
        intentPaymentData = null;
      })
          // .onError(errorMsg, sTrace){
          //   if(kDebugMode){
          //     print(errorMsg.toString()+ sTrace());
          //   }
          // }
          ;
    } on StripeException catch (error) {
      if (kDebugMode) {
        print(error);
      }
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
                content: Text("Cancelled"),
              ));
    } catch (e) {}
  }

  makeIntentForPayment(amount, currency) async {
      print('in makeIntentForPayment');
    try {
      Map<String, dynamic>? paymentInfo = {
        "amount": (int.parse(amount) * 100).toString(),
        "currency": currency,
        "payment_method_types[]": "card",
      };
      var responseFromStripeApi = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: paymentInfo,
          headers: {
            "Authorization": "Bearer $Secretkey",
            "Content-Type": "application/x-www-form-urlencoded"
          });
      print("response from API = " + responseFromStripeApi.body);
      return jsonDecode(responseFromStripeApi.body);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  paymentSheetInitialization(amount, currency) async {
    print('in paymentSheetInitialization');
    try {
      intentPaymentData = await makeIntentForPayment(amount, currency);

      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                  allowsDelayedPaymentMethods: true,
                  paymentIntentClientSecret:
                      intentPaymentData!["client_secret"],
                  style: ThemeMode.dark,
                  merchantDisplayName: "Company Name example"
                  )
                  )
          .then((val) {
        print(val);
      });
      showPaymentSheet();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(children: [
          ElevatedButton(
            onPressed: () {
              paymentSheetInitialization(amount.round().toString(), "USD");
            },
            child: Text("pay now ${amount.toString()}"),
          ), 

        ]),
      ),
    ));
  }
}
