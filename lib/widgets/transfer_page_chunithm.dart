import 'package:flutter/material.dart';

class TransferPageChunithm extends StatefulWidget {
  const TransferPageChunithm({super.key});

  @override
  State<TransferPageChunithm> createState() => _TransferPageChunithmState();
}

class _TransferPageChunithmState extends State<TransferPageChunithm> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          Text("中二节奏 成绩上传配置", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("此处将显示中二节奏特定的勾选内容"),
          // TODO: Checkboxes for difficulty, chart type, etc.
        ],
      ),
    );
  }
}
