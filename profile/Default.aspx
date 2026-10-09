<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsProfile" %>

<!DOCTYPE html>
<html>
<head>
    <title>Profile</title>
</head>
<body>

    <!--<asp:Image class="imgAvatar" Height="90px" Width="90px" ImageUrl="../profile/GetProfileAvatar.ashx" id="imgAvatar" runat="server" /><br/>
    <a href="javascript:changeAvatar()">Cambiar Foto</a><br/>-->
    <img src="../img/avatar2.png" class="w3-circle w3-margin-right" style="width:46px">
    <asp:Label id="lblAgentValue" runat="server" Text=""></asp:Label><br/>

    <div class="w3-bar w3-dark-grey">
        <button class="w3-bar-item w3-button w3-grey tablink" onclick="openTab(event, 'info')">Información Personal</button>
        <button class="w3-bar-item w3-button tablink" onclick="openTab(event, 'groups')">Mis Grupos</button>
        <button class="w3-bar-item w3-button tablink" onclick="openTab(event, 'security')">Seguridad</button>
    </div>

    <div id="info" class="w3-container profile">
      <h2>Información Personal</h2>
        <div id="loaderProfile" class="fa fa-spinner w3-spin w3-xxxlarge" style="display: none;"></div>
        <div id="editProfile"></div>
        <div class="isa_success" id="resultOK" style="display:none"></div>
        <div class="isa_error" id="resultError" style="display:none"></div>
    </div>

    <div id="groups" class="w3-container profile" style="display:none">
      <h2>Mis Grupos</h2>
      <%=GetGroupsAsHTML()%>
    </div>

    <div id="security" class="w3-container profile" style="display:none">
       <h2>Seguridad</h2>
        <div id="loaderSecurity" class="fa fa-spinner w3-spin w3-xxxlarge" style="display: none;"></div>
        <div id="editSecurity">
           <form id="profile_pwd_form_id" class="w3-container">
                <p><label>Contraseña Actual: </label>
                <input class="w3-input" type="password" name="txtCurrentPwd"/></p>
                <p><label for="txtNewPwd">Contraseña Nueva: </label>
                <input class="w3-input" type="password" name="txtNewPwd"/></p>
                <p><label for="txtReNewPwd">Repetir Nueva Contraseña: </label>
                <input class="w3-input" type="password" name="txtReNewPwd"/></p>

                <button class="w3-button w3-dark-grey" onclick="savePassword();return false;">Grabar</button>
           </form>
        </div>
        <div class="isa_success" id="resultSecOK" style="display:none"></div>
        <div class="isa_error" id="resultSecError" style="display:none"></div>
    </div>
    
    <script src="../js/profile.js"></script>
    <script>

        editProfile();

    </script>
   
</body>
</html>