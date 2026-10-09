<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsTask" %>

<!DOCTYPE html>
<html>
<head>
    <title>Task</title>

</head>
<body>

    <%=ShowScreen()%>
    <script>
       $(document).ready(function() {
           initDataTables();
        });
   </script>
</body>
</html>