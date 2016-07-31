function readURL(input) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();

    reader.onload = function (e) {
      $('#logo_img')
        .attr('src', e.target.result)
        .width(500)
        .height(200);
    };

    reader.readAsDataURL(input.files[0]);
  }
}
