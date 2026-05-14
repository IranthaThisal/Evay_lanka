import 'package:flutter/material.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  final String _policy = '''Privacy Policy

Effective Date: May 14, 2026

Updated on: May 14, 2026

Privacy is important. We respect yours.

General information

This policy sets out our privacy practices and explains how we handle the information we collect when you visit and use our site/s and content provided by EvayLanka, in existence now or in the future ("EvayLanka Services"). Please read it carefully.

What we may collect

To enhance your user experience while utilizing our Service, we may ask for certain personally identifiable information, such as your Name, Email Address, Phone Number, Sexual Orientation, Users' Image Information, and Device ID. Any information we collect from you will be securely stored and utilized as outlined in our Privacy Policy.

Also we collect information about what EvayLanka pages you access or visit, information about your mobile device (such as device or browser type), information volunteered by you (such as through registration), the URLs of websites that referred you to us, and e-mail addresses of those who communicate with us via email.

When you log into EvayLanka Services or load a web page from EvayLanka Services, we collect and store your Internet Protocol address. We may use this information to fight spam, malware, and identity theft; to personalize EvayLanka Services for you; or to generate aggregate, non-identifying information about how people use EvayLanka Services.

When you create your EvayLanka account, and authenticate via a third-party service like Google or Facebook, we will not collect any details of your contacts, but we may collect the "minimal" information needed to uniquely identify your account, such as your third party account ID, associated email and other such personal information.

Email communications with us

We may occasionally need to email you some administrative info, tell you something important about your account or changes to our services, or update you on new policies. In really tough situations, we might just need to vent about how unfair life is. Except for that last scenario, which will not actually happen, these administrative communications are considered a basic part of EvayLanka Services, and you may not be able to opt out from receiving them. You can always opt out of non-administrative emails.

We will never email you to ask for your password or other account information. If you receive such an email, send it to us so we can take action against the evildoer.

Disclosure of your information

The information we collect is used to provide and improve EvayLanka Services and content and prevent abuse. We do not sell personal information about our users to any third party, unless you have been informed so and permission given on your end.

While EvayLanka endeavours to provide the highest level of protection for your information, we may share your personal information with third parties in limited circumstances, including: (1) with your consent; or (2) when we have a good faith belief it is required by law, such as pursuant to a subpoena or other judicial or administrative order.

Please note that for the purpose of the promotional schemes we may carry out, the information you provide to us may be submitted to our sponsors. This includes your email and the mobile number. We ensure that the sponsors would maintain strict confidentiality regarding the personal data you provide us with and no member would be individually identified.

If we are going to release your information, our policy is to provide you with advance notice unless we are prohibited from doing so by law or court order. If you do not challenge the disclosure request, we may be legally required to turn over your information.

We may disclose your information without providing you with prior notice if we believe it is necessary to prevent imminent and serious bodily harm to a person. In that case, we will endeavour to provide you with post-disclosure notice when permitted by law.

We will independently object to requests for access to information about users of our site that we believe to be improper.

If we are acquired by or merged with another company and your information becomes subject to a different privacy policy, we will notify you before the transfer. You can opt out of the new policy by deleting your account during the notice period.

Cookies

A cookie is a small piece of text, which often includes an anonymous unique identifier, sent to and saved by your web browser when you access a website.

WordPress uses cookies to enable servers to recognize your web browser and tell us how and when you use EvayLanka Services. We use cookies to identify whether you have logged in and recognize that your web browser has accessed aspects of EvayLanka Services, and we may associate that information with your account if you have one. This information, in turn, is sometimes used to personalize your experiences on EvayLanka Services when you are logged in.

Most browsers have an option for disabling cookies, but if you disable them you may not be able to log into your EvayLanka account, and will not be able to use the vast majority of EvayLanka Services.

Some other third-party apps and services that are used in the EvayLanka apps / web portal may place their own cookies in your browser. Note that this Privacy Policy covers our use of cookies only and not the use of cookies by third parties.

Data storage

EvayLanka is hosted on Amazon Web Services, and it provides the necessary hardware, software, networking, storage, and related technologies we need to run EvayLanka. Amazon may maintain copies of data in their servers to ensure seamless service and backup purposes. The use of such data is subject to privacy policies explained therein, and is not covered via this policy.

Modifying your personal information or deleting your account

If you are a registered EvayLanka user, you can access or modify your personal information by logging into our web portal or via our app. Should you need to delete your account, you could do so by personally informing us.

Once an account is deleted your data will be permanently unrecoverable, unless you explicitly request to keep the data on our servers.

Data security

We use encryption (HTTPS/TLS) to protect data transmitted to and from our site, wherever possible. However, no data transmission over the Internet is 100% secure, so we cannot guarantee the absolute security of this data. You use the service at your own risk, and you are responsible for taking reasonable measures to secure your account (such as keeping your password secret).

Changes to this policy
EvayLanka may periodically update this policy.
We will notify you about significant changes in the way we treat personal information by sending a notice to the primary email address specified in your EvayLanka account or by placing a prominent notice on our site / app before the changes take effect.
Questions

We welcome questions, concerns, and feedback about this policy.
If you have any suggestions for us, feel free to let us know at info@evaylanka.lk.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          _policy,
          style: const TextStyle(fontSize: 14.0, height: 1.4),
        ),
      ),
    );
  }
}
