var activeTab = $('#user-tabs').data('active');
$('#user-tabs a[href="#' + activeTab + '"]').tab('show')
