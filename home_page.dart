import 'dart:io';
import 'dart:math' as Math;

import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodzzz_restaurent2/models/restaurentDetails.dart';
import 'package:foodzzz_restaurent2/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:foodzzz_restaurent2/models/todo.dart';
import 'dart:async';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Img;
class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> _todoList;
  String userId="";

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;

 // Query _todoQuery;

  bool _isEmailVerified = false;

  void inputData() async {
    final FirebaseAuth auth=FirebaseAuth.instance;
    final FirebaseUser user = await auth.currentUser();
    final uid = user.uid;
    userId=user.uid;
    print("Input data called");
    // here you write the codes to input the data into firestore
  }

  @override
  void initState() {
    super.initState();

    inputData();
    print("Inside init");
    print("UID is"+userId);
    _checkEmailVerification();

    _todoList = new List();
//    _todoQuery = _database
//        .reference()
//        .child("todo")
//        .orderByChild("userId")
//        .equalTo(widget.userId);
//    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
//    _onTodoChangedSubscription = _todoQuery.onChildChanged.listen(_onEntryChanged);
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail(){
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Please verify account in the link sent to email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Resent link"),
              onPressed: () {
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = _todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _todoList[_todoList.indexOf(oldEntry)] = Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  _addNewTodo(String todoItem) {
    if (todoItem.length > 0) {

      Todo todo = new Todo(todoItem.toString(), widget.userId, false);
      _database.reference().child("todo").push().set(todo.toJson());
    }
  }

  _updateTodo(Todo todo){
    //Toggle completed
    todo.completed = !todo.completed;
    if (todo != null) {
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  _deleteTodo(String todoId, int index) {
    _database.reference().child("todo").child(todoId).remove().then((_) {
      print("Delete $todoId successful");
      setState(() {
        _todoList.removeAt(index);
      });
    });
  }


  Widget _showTodoList() {
    if (_todoList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _todoList.length,
          itemBuilder: (BuildContext context, int index) {
            String todoId = _todoList[index].key;
            String subject = _todoList[index].subject;
            bool completed = _todoList[index].completed;
            String userId = _todoList[index].userId;
            return Dismissible(
              key: Key(todoId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deleteTodo(todoId, index);
              },
              child: ListTile(
                title: Text(
                  subject,
                  style: TextStyle(fontSize: 20.0),
                ),
                trailing: IconButton(
                    icon: (completed)
                        ? Icon(
                      Icons.done_outline,
                      color: Colors.green,
                      size: 20.0,
                    )
                        : Icon(Icons.done, color: Colors.grey, size: 20.0),
                    onPressed: () {
                      _updateTodo(_todoList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(child: Text("Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  TextEditingController Name=new TextEditingController();
  TextEditingController Mobile=new TextEditingController();
  TextEditingController Address=new TextEditingController();
  TextEditingController Gstn=new TextEditingController();
  TextEditingController PAN=new TextEditingController();

  TextEditingController Food=new TextEditingController();
  TextEditingController Price=new TextEditingController();
  File _image;
  Future getImageGallery() async{
    var imageFile=await ImagePicker.pickImage(source: ImageSource.gallery);

    final tempDir=await getTemporaryDirectory();
    final path=tempDir.path;

    final id=await FirebaseAuth.instance.currentUser();
    String uid=id.uid;
    int rand=Math.Random().nextInt(100000);

    Img.Image image=Img.decodeImage(imageFile.readAsBytesSync());
    Img.Image smallerImage=Img.copyResize(image, 500);
    var compressImg=File("$path/image_$uid.jpg")
    ..writeAsBytesSync(Img.encodeJpg(smallerImage,quality: 85));


    setState(() {
      _image=imageFile;
    });
  }
  Future getImageCamera() async{
    var imageFile=await ImagePicker.pickImage(source: ImageSource.camera);
    final tempDir=await getTemporaryDirectory();
    final path=tempDir.path;

    final id=await FirebaseAuth.instance.currentUser();
    String uid=id.uid;

    Img.Image image=Img.decodeImage(imageFile.readAsBytesSync());
    Img.Image smallerImage=Img.copyResize(image, 500);
    var compressImg=File("$path/image_$uid.jpg")
      ..writeAsBytesSync(Img.encodeJpg(smallerImage,quality: 85));


    setState(() {
      _image=imageFile;
    });
  }

  Future upload(File imageFile,String UserId) async{
    var steam=http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length=await imageFile.length();
    var uri=Uri.parse("https://commerceguru.000webhostapp.com/setFoodDetails.php");
    var request=http.MultipartRequest("POST",uri);
    request.fields['uid']=UserId;
    request.fields['foodname']=Food.text;
    request.fields['foodprice']=Price.text;
    var multipartFile=http.MultipartFile("image",steam,length,filename: basename(imageFile.path));
    request.files.add(multipartFile);
    var response=await request.send();
    if(response.statusCode==200){
      print("DATA UPLOADED");
    }
    else{
      print("FAILED");
    }
  }
  addFood(BuildContext context) async {

    await showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          content: Column(
            children: <Widget>[
              Expanded(
                child:TextField(controller:Food,decoration: InputDecoration(hintText: "Enter Food Name",labelText: "Enter Food Name"),),
              ),
              Expanded(
                child:TextField(controller:Price,decoration: InputDecoration(hintText: "Enter Food Price",labelText: "Enter Food Price"),),
              ),
             Expanded(
               child: _image==null?Text("No Image Selected"):Image.file(_image),
             ),

             Row(
               children: <Widget>[
                 MaterialButton(
                   child:Text("Gallery"),
                   onPressed: getImageGallery,
                 ),
                 MaterialButton(
                   child:Text("Camera"),
                   onPressed: getImageCamera,
                 ),

               ],
             ),

            ],
          ),
          actions: <Widget>[
            FutureBuilder(
              future: FirebaseAuth.instance.currentUser(),
              builder: (context,AsyncSnapshot<FirebaseUser> snapshot){
                if(snapshot.hasData){
                  return  FlatButton(
                    child: Text("Continue"),
                    onPressed: (){
                      upload(_image,snapshot.data.uid);

                    },
                  );
                }
                else{
                  return Text('Loading...');

                }
              },

            ),

            FlatButton(
              child: Text("Cancel"),
              onPressed: ()=>Navigator.of(context).pop(),
            ),
          ],
        );

      }
    );

  }




  Widget RestaurentProfile(){

    return FutureBuilder(
      future: FirebaseAuth.instance.currentUser(),
      builder: (context, AsyncSnapshot<FirebaseUser> snapshot) {
        if (snapshot.hasData) {
          return
          ListView(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(25.0),),
              TextField(controller:Name,decoration: InputDecoration(labelText: "Enter Restaurent Name",hintText: "Enter Restaurent Name"),),
              TextField(controller:Mobile,decoration: InputDecoration(labelText: "Enter Restaurent Mobile Number",hintText: "Enter Restaurent Mobile Number"),),
              TextField(controller:Address,decoration: InputDecoration(labelText: "Enter Address with Pincode",hintText: "Enter Address With Pincode"),),
              TextField(controller:Gstn,decoration: InputDecoration(labelText: "Enter Adhaar Number",hintText: "Enter Adhaar Number"),),
              TextField(controller:PAN,decoration: InputDecoration(labelText: "Enter PAN Number",hintText: "Enter PAN Number"),),
              MaterialButton(
                color: Colors.blue,
                child: Text("UPDATE"),
                onPressed: (){
                  var url="https://commerceguru.000webhostapp.com/setRestaurentDetails.php";

                  http.post(url,body: {
                    'uid':snapshot.data.uid,
                    'name':Name.text,
                    'address':Address.text,
                    'mobile':Mobile.text,
                    'gstnumber':Gstn.text,
                    'pannumber':PAN.text,
                  });
                  print("DATA UPLOADED");
//                final FirebaseDatabase _database = FirebaseDatabase.instance;
//                DocumentReference ref=Firestore.instance.collection("RestaurentDetail").document(snapshot.data.uid);
//                String name=Name.text;
//                String mobile=Mobile.text;
//                String address=Address.text;
//                String gstn=Gstn.text;
//                String pan=PAN.text;
//                Map<String,String> res_data=<String,String>{
//                  "name":name,
//                  "mobile":mobile,
//                  "address":address,
//                  "gstn":gstn,
//                  "pan":pan,
//
//                };
////                FirebaseUser user=FirebaseAuth.instance.currentUser();
//                Res obj=new Res(name,mobile,address,gstn,pan);
//                _database
//                    .reference()
//                    .child("RestaurentDetails")
//                    .child(snapshot.data.uid)
//                    .set(obj.toJson());
//
//                ref.setData(res_data).whenComplete((){
//                  print("Data uploaded");
//                }).catchError((e)=>print(e));
//
//
//


              },
              ),

            ],

          );
        }
        else {
          return Text('Loading...');
        }
      },
    );



  }

  int id=0;
  @override
  Widget build(BuildContext context) {



    final tabpages=<Widget>[
      _showTodoList(),
      Center(child: Icon(Icons.map,size: 60.0,color: Colors.red,),),
      Center(child: Icon(Icons.mic,size: 60.0,color: Colors.red,),),
      RestaurentProfile(),
    ];
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Restaurent HomePage'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        body:tabpages[id],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            addFood(context);
          },
          tooltip: 'Add Food',
          child: Icon(Icons.add),
        ),
      bottomNavigationBar: CurvedNavigationBar(
        items: <Widget>[
          Icon(Icons.home,color: Colors.white,),
          Icon(Icons.email,color: Colors.white,),
          Icon(Icons.add_call,color: Colors.white,),
          Icon(Icons.person,color: Colors.white,),
        ],
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        animationCurve: Curves.easeIn,
        animationDuration: Duration(milliseconds: 600),
        onTap: (int index){
          setState(() {
            id=index;
          });
        },
      ),
    );
  }
}
