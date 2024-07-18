<?php
$paths = $_POST['paths'];

unlink("../" . $paths[0]);

echo $paths[0];
?>