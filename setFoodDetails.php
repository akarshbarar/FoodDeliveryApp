<?php

include 'cofig.php';
$uid=$_POST['uid'];
$foodname=$_POST['foodname'];
$foodprice=$_POST['foodprice'];

$image=$_FILES['image']['name'];
$imagePath="uploads/".$image;
move_uploaded_file($_FILES['image']['tmp_name'],$imagePath);


$conn->query("INSERT INTO FoodDetails  VALUES ('".$uid."','".$foodname."','".$foodprice."','".$image."')");

?>
