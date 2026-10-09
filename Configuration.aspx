<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsConfiguration" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>SofiaWeb</title>
    <style type="text/css">
        @import "../lib/dojo/dijit/themes/claro/claro.css";
        @import "../lib/dojo/dojo/resources/dojo.css";
        @import "../css/HtmlGrid.css";        
    </style>
    <script type="text/javascript" src="../lib/dojo/dojo/dojo.js" djConfig="parseOnLoad:true"></script>
	<style type="text/css">
		.claro .dijitDialogUnderlay { background:#000; }
	</style>    
</head>
<body class="claro">
    <div data-dojo-type="dijit.layout.ContentPane">
	    <asp:Image class="imgAvatar" ImageUrl="../img/avatar.jpg" ID="imgAvatar"  runat="server" /><br/>
        <asp:Label id="lblAgentValue" runat="server" Text=""></asp:Label><br/>
        <asp:Label id="lblUnitValue" runat="server" Text=""></asp:Label>
    </div>
</body>
</html>