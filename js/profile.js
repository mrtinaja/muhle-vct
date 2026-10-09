function openTab(evt, tab) {
    var i;
    var x = document.getElementsByClassName("profile");
    for (i = 0; i < x.length; i++) {
        x[i].style.display = "none";
    }
    tablinks = document.getElementsByClassName("tablink");
    for (i = 0; i < x.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" w3-grey", "");
    }
    document.getElementById(tab).style.display = "block";
    evt.currentTarget.className += " w3-grey";
    
}

function editProfile() {

    $.ajax({
        type: 'GET',
        url: '../profile/EditProfile.ashx',
        dataType: "text",
        success: function (data) {
            $("#editProfile").html(data);
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function savePassword() {
    var form = $('#profile_pwd_form_id');
    $('#editSecurity').hide();
    $("#resultSecError").hide();
    $("#resultSecOK").hide();
    $('#loaderSecurity').show();

    $.ajax({
        type: 'POST',
        url: '../profile/ChangeProfilePassword.ashx',
        data: form.serialize(),
        dataType: "text",
        success: function (data) {
            if (data == 'OK') {
                $("#resultSecOK").html('La contraseña ha sido cambiada con éxito.');
                $("#resultSecOK").show();
            } else {
                $("#resultSecError").html('Se ha producido un error: ' + data);
                $("#resultSecError").show();
            }
            $('#loaderSecurity').hide();
            $('#editSecurity').show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function saveProfile() {
    var form = $('#profile_form_id');
    $('#editProfile').hide();
    $("#resultError").hide();
    $("#resultOK").hide();
    $('#loaderProfile').show();

    $.ajax({
        type: 'POST',
        url: '../profile/SaveProfile.ashx',
        data: form.serialize(),
        dataType: "text",
        success: function (data) {
            if (data == 'OK') {
                $("#resultOK").html('Los datos han sido guardados correctamente.');
                $("#resultOK").show();
            } else {
                $("#resultError").html('Se ha producido un error: ' + data);
                $("#resultError").show();
            }
            $('#loaderProfile').hide();
            $('#editProfile').show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}