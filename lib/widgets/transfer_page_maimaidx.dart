import 'package:flutter/material.dart';

class TransferPageMaimaiDx extends StatefulWidget {
  const TransferPageMaimaiDx({super.key});

  @override
  State<TransferPageMaimaiDx> createState() => _TransferPageMaimaiDxState();
}

class _TransferPageMaimaiDxState extends State<TransferPageMaimaiDx> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          Text("舞萌 DX 成绩上传配置", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("此处将显示舞萌特定的勾选内容"),
          // TODO: Checkboxes for difficulty, chart type, etc.
        ],
      ),
    );
  }
}
