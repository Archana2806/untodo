import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController taskController = TextEditingController();
  String filter = 'All';

  void addTodo() async {
    final text = taskController.text.trim();
    if (text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('todos').add({
        'task': text,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
      taskController.clear();
    }
  }

  void toggleComplete(DocumentSnapshot doc) {
    FirebaseFirestore.instance
        .collection('todos')
        .doc(doc.id)
        .update({'completed': !doc['completed']});
  }

  void deleteTodo(DocumentSnapshot doc) {
    FirebaseFirestore.instance.collection('todos').doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4C9),
        title: const Text('TO DO', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      hintText: 'Add a new task',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: addTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB6E2D3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ToggleButtons(
              isSelected: [
                filter == 'All',
                filter == 'Completed',
                filter == 'Pending'
              ],
              onPressed: (index) {
                setState(() {
                  filter = ['All', 'Completed', 'Pending'][index];
                });
              },
              borderRadius: BorderRadius.circular(20),
              selectedColor: Colors.white,
              fillColor: const Color(0xFFFFB5A7),
              color: Colors.black,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
              children: const [
                Text('All'),
                Text('Completed'),
                Text('Pending'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('todos')
                  .where('uid', isEqualTo: uid)
                  .where('timestamp', isNotEqualTo: null)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error.toString()}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tasks yet 🐥'));
                }

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  if (filter == 'All') return true;
                  if (filter == 'Completed') return doc['completed'] == true;
                  return doc['completed'] == false;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          shape: const CircleBorder(),
                          activeColor: const Color(0xFFA0CED9),
                          value: doc['completed'],
                          onChanged: (_) => toggleComplete(doc),
                        ),
                        title: Text(
                          doc['task'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            decoration: doc['completed']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => deleteTodo(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
