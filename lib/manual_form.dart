import 'package:course_query/gemini_helper.dart';
import 'package:flutter/material.dart';

class ManualFormWidget extends StatefulWidget {
  const ManualFormWidget({super.key});

  @override
  State<ManualFormWidget> createState() => _ManualFormWidgetState();
}

class _ManualFormWidgetState extends State<ManualFormWidget> {
  final courseCode = TextEditingController();
  final sectionCode = TextEditingController();
  final courseInfo = TextEditingController();
  final minCredits = TextEditingController();
  final maxCredits = TextEditingController();
  bool? byAgreement;
  final startTime = TextEditingController();
  final endTime = TextEditingController();
  final days = TextEditingController();
  bool invertDays = false;
  final room = TextEditingController();
  final professorName = TextEditingController();
  final projectionType = TextEditingController(text: "section");

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Manual Form"),
      content: _formatForm([
        Row(
          children: [
            Expanded(
                child: TextField(
              controller: courseCode,
              decoration: const InputDecoration(labelText: "Course Code"),
            )),
            const Text(" — "),
            Expanded(
              child: TextField(
                controller: sectionCode,
                decoration: const InputDecoration(labelText: "Section Code"),
              ),
            )
          ],
        ),
        TextField(
          controller: courseInfo,
          decoration: const InputDecoration(labelText: "Course Info"),
        ),
        Row(
          children: [
            Expanded(
                child: TextField(
              controller: minCredits,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Min Credits"),
            )),
            const Text(" — "),
            Expanded(
              child: TextField(
                controller: maxCredits,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max Credits"),
              ),
            )
          ],
        ),
        Row(
          children: [
            const Text("By Agreement"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Checkbox(
                  tristate: true,
                  value: byAgreement,
                  onChanged: (value) {
                    setState(() {
                      byAgreement = value;
                    });
                  }),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
                child: TextField(
              controller: startTime,
              decoration: const InputDecoration(labelText: "Start Time"),
            )),
            const Text(" — "),
            Expanded(
              child: TextField(
                controller: endTime,
                decoration: const InputDecoration(labelText: "End Time"),
              ),
            )
          ],
        ),
        TextField(
          controller: days,
          decoration: const InputDecoration(labelText: "Days"),
        ),
        Row(
          children: [
            const Text("Invert Days"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Checkbox(
                  value: invertDays,
                  onChanged: (value) {
                    setState(() {
                      invertDays = value!;
                    });
                  }),
            ),
          ],
        ),
        TextField(
          controller: room,
          decoration: const InputDecoration(labelText: "Room"),
        ),
        TextField(
          controller: professorName,
          decoration: const InputDecoration(labelText: "Professor Name"),
        ),
        DropdownMenu(
          controller: projectionType,
          label: const Text("Projection Type"),
          dropdownMenuEntries: [
            "section",
            "course",
            "professor",
            "course_code",
            "course_name",
            "course_description",
            "course_credits",
            "course_requisites",
            "course_prerequisites",
            "course_corequisites",
            "section_code",
            "section_modality",
            "meeting_start_time",
            "meeting_end_time",
            "meeting_days",
            "meeting_room",
            "professor_name"
          ].map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
        )
      ]),
      actions: [
        TextButton(
            onPressed: () async {
              final form = {
                "course_code": _nullIfEmpty(courseCode.text),
                "section_code": _nullIfEmpty(sectionCode.text),
                "course_info": courseInfo.text.isNotEmpty
                    ? await generateEmbedding(courseInfo.text)
                    : null,
                "min_credits": int.tryParse(minCredits.text),
                "max_credits": int.tryParse(maxCredits.text),
                "by_agreement": byAgreement,
                "start_time": _nullIfEmpty(startTime.text),
                "end_time": _nullIfEmpty(endTime.text),
                "days": _nullIfEmpty(days.text),
                "invert_days": invertDays,
                "room": _nullIfEmpty(room.text),
                "professor_name": professorName.text.isNotEmpty
                    ? await generateEmbedding(professorName.text)
                    : null,
                "projection_type": projectionType.text,
              };
              if (context.mounted) {
                Navigator.pop(context, form);
              }
            },
            child: const Text("Submit"))
      ],
    );
  }
}

String? _nullIfEmpty(String s) => s.isEmpty ? null : s;

Widget _formatForm(List<Widget> rows) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 400),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows
            .expand((e) => [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: e,
                  ),
                  if (e != rows.last) const Divider(),
                ])
            .toList(),
      ),
    ),
  );
}
