<?php
include 'cofig.php';
$id=$_POST['id'];
$uid=$_POST['uid'];
$name=$_POST['name'];
$address=$_POST['address'];
$mobile=$_POST['mobile'];
$gstnumber=$_POST['gstnumber'];
$pannumber=$_POST['pannumber'];
$conn->query("INSERT INTO RestaurentDetails  VALUES ('".$uid."','".$name."','".$address."','".$mobile."','".$gstnumber."','".$pannumber."')");
?>
