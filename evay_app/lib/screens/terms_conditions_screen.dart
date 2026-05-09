import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  final String _terms = '''Effective Date: February 1, 2018

Updated on: February 1, 2018

We’ll try to make this as painless and straightforward as possible.

This is a contract (“Terms”) between you and evaylanka (“evaylanka,” “we,” or “us”), applicable when you use our site/s and content provided by evaylanka, globally, in existence now or in the future (“evaylanka Services”).

These terms are a binding agreement

Even if your eyes normally glaze over the word “Terms,” it’s a good idea to read this agreement carefully before you use evaylanka. For one thing, we want your feedback and suggestions on how to make our service better. (We’d really like to hear from you: email your input to info@evaylanka.lk) For another, by using evaylanka Services, you agree to be bound by everything in these Terms. If you don’t agree to the Terms, please don’t use evaylanka.

Administrators

Please note that evaylanka administrators treat your information – charging data, personal information etc. with utmost confidentiality and security and none of your contents would be shared with any other party (other than the site administrators), without your expressed consent.

You are free to delete your evaylanka account any time, and may do so by informing us. Due to the logistical changes that need to be done, this process is not automated. We do not maintain any backup of sorts of your data. Therefore, once your account is deleted, the data in it may be permanently unrecoverable, and this includes any account balance which was left in your account at the time of deleting.

Liability

The Electric Vehicle (EV) charging facility is powered by evaylanka (Pvt) Ltd., the chargers are manufactured according to J1772 and CHAdeMO international standards. Once you register, you may use the evaylanka smart charge card or the evaylanka Android app to charge your EV.

Certain chargers are maintained by third parties and evaylanka only provides the evaylanka charging service, know-how and infrastructure. Please note that evaylanka or any of its subsidiary entities will NOT be liable for any damage caused to any such property, charging unit or the EV, due to the negligence, misuse and / or misconduct of a user of the EV charging facility. Any such loss to either party will be borne by the user of the facility, and upon signing up to use evaylanka services, the user agrees to indemnify evaylanka of any such losses.

Furthermore, evaylanka is NOT involved in providing any consultancy / advise related services regarding repairs / spare parts / performance of electric vehicles. As such evaylanka will not be liable in any way for implication/s arising out of opinions expressed / representations made – expressed or implied, by any of evaylanka’s employees. Users are advised to utilise such advice at their own risk.

Users are advised to refrain from charging your EV under lightning and stormy weather conditions. You may always contact evaylanka on 077 0 555 553 for any emergency or EV charging related matters.

Our content

The look and feel of evaylanka Services are copyright of evaylanka. All rights reserved.

We may modify these Terms at any time

We can change these Terms at any time. If the changes are material, we’ll let you know by email or posting a notice on the site before the changes go into effect. The notice will designate a reasonable amount of time (the “Notice Period”) after which the new terms will go into effect for all users. If you don’t agree to the new terms, you may delete your account within the Notice Period. If you do not delete your account within the Notice Period, your content and use of the services will be subject to the new terms going forward.

We may modify our Services at any time

We do our best to provide you a reliable and evolving service, but we may change, terminate, or restrict access to any aspect of the service, at any time, without notice.

Privacy

When you use evaylanka Services, you consent to the collection and use of information as detailed in our Privacy Policy. If you’re outside Sri Lanka, you consent to the transfer, storage, and processing of your information – including but not limited to, the content you posted or transferred to the site and any personal information – to and within Sri Lanka and other countries.

Security and responsible disclosures

We take security very seriously, and are always on the lookout for opportunities to make our service better. If you feel any portion of the web site and related security components have been compromised, please report it immediately by emailing us. We will take prompt steps to remedy any unusual experience that you may have had at evaylanka.

Third-party account use for sign-ins

We currently use third parties like Google and Facebook to create and authorize user accounts. By using those third-party services, you agree to their terms of use, privacy policy, and other agreements between you and them.

Our rules

Your relationship with evaylanka is governed by the rules mentioned here. Please read them carefully before using any of the services of evaylanka.

Copyright policy

evaylanka deals with copyright infringement on evaylanka Services in accordance with the local data protection and intellectual property laws of Sri Lanka.

Miscellaneous provisions (please read these carefully)

YOU USE THE EVAYLANKA SERVICES AT YOUR OWN RISK. THE SERVICES ARE PROVIDED ON AN “AS IS” AND “AS AVAILABLE” BASIS.

EVAYLANKA MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO EVAYLANKA SERVICES. FOR EXAMPLE, WE DO NOT WARRANT THAT:

THE SERVICE WILL MEET YOUR SPECIFIC REQUIREMENTS,
THE SERVICE WILL BE UNINTERRUPTED, TIMELY, ABSOLUTELY SECURE, OR ERROR-FREE,
THE QUALITY OF ANY PRODUCTS, SERVICES, INFORMATION, OR OTHER MATERIAL PURCHASED OR OBTAINED BY YOU THROUGH THE SERVICE WILL MEET YOUR EXPECTATIONS, OR
ANY ERRORS IN THE EVAYLANKA SERVICES WILL BE CORRECTED.
YOU UNDERSTAND AND EXPRESSLY AGREE THAT EVAYLANKA SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR EXEMPLARY DAMAGES, INCLUDING, BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA OR OTHER INTANGIBLE LOSSES (EVEN IF EVAYLANKA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES), RESULTING FROM:

THE USE OR THE INABILITY TO USE THE SERVICE;
THE COST OF PROCUREMENT OF SUBSTITUTE GOODS AND SERVICES RESULTING FROM ANY GOODS, DATA, INFORMATION OR SERVICES PURCHASED OR OBTAINED OR MESSAGES RECEIVED OR TRANSACTIONS ENTERED INTO THROUGH OR FROM THE SERVICE;
UNAUTHORIZED ACCESS TO OR ALTERATION OF YOUR TRANSMISSIONS OR DATA;
STATEMENTS OR CONDUCT OF ANY THIRD PARTY ON THE SERVICE; OR
ANY OTHER MATTER RELATING TO THE EVAYLANKA SERVICES.

THE FAILURE OF EVAYLANKA TO EXERCISE OR ENFORCE ANY RIGHT OR PROVISION OF THESE TERMS SHALL NOT CONSTITUTE A WAIVER OF THAT RIGHT OR PROVISION. THE TERMS AND OUR PRIVACY POLICY CONSTITUTE THE ENTIRE AGREEMENT BETWEEN YOU AND EVAYLANKA AND GOVERN YOUR USE OF THE EVAYLANKA SERVICES, SUPERSEDING ANY PRIOR AGREEMENTS BETWEEN YOU AND EVAYLANKA (INCLUDING, BUT NOT LIMITED TO, ANY PRIOR VERSIONS OF THE TERMS). YOU AGREE THAT THESE TERMS AND YOUR USE OF THE EVAYLANKA SERVICES ARE GOVERNED UNDER SRI LANKAN LAW. BEFORE RESORTING TO COURTS, WE STRONGLY ENCOURAGE YOU TO CONTACT US DIRECTLY TO TRY TO WORK IT OUT.

We’d love to hear your questions, concerns, and feedback about this policy. If you have any suggestions for us, feel free to let us know at info@evaylanka.lk.

The End.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          _terms,
          style: const TextStyle(fontSize: 14.0, height: 1.4),
        ),
      ),
    );
  }
}
