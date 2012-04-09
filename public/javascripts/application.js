// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


var ec = new function() {
    var self=this;
    self.servers = {}

    self.get_servers = function() {
        $.ajax({
            url: '/servers/monitor/',
            success: function(data) {
                //console.log(data);
                self.servers = data;
                $.each(self.servers, function(i, server) { server.last_id = -1; server.updates = [];});
                self.update_stats();
            }
        });
    };
    self.update_stats = function() {
        console.log('update stats');
        $.each(self.servers, self.update_server_stats);
    };

    self.update_server_stats = function(i, server) {
        $.ajax({
            url: '/servers/monitor_update/'+server.server.name+'/',
            data: {
                from_id: server.last_id
            },
            success: function(data) {
                server.last_id = data.cur_id-1;
                $.each(data.data, function(j, d) { server.updates.push(d); });
                self.update_server_display(server);
                setTimeout(function() {self.update_server_stats(i, server);}, 2000);
            }
        });
    };

    self.update_server_display = function(server) {
        server.updates.splice(0,server.updates.length-60);
        try {
            var last_update = server.updates[server.updates.length-1];
            var selector = '#Server_'+server.server.id+'';
            if (typeof last_update.vms != "undefined") {
              $(selector+' .capacity').html(last_update.vms+' VMs');
            } else {
              $(selector+' .capacity').html('');
            }
            $(selector+' .ram').html(last_update.mem+' MB');
            $(selector+' .load').html(Math.round(last_update.cpu*100)/100);
            $(selector+' .latency').html(' acceptable');
            $(selector+' .ramgraph').sparkline(server.updates.map(function(x) { return x.mem.substr(0,x.mem.indexOf('/')); }), {width: 75, chartRangeMin: 220, chartRangeMax: 350});
            /* chartRangeMin: 0, chartRangeMax:last_update.mem.substr(last_update.mem.indexOf('/')+1), */
            $(selector+' .loadgraph').sparkline(server.updates.map(function(x) { return x.cpu; }), {width: 75, chartRangeMin: 0.10, chartRangeMax: 1.00});
        } catch(e) {
            if(console && console.log) {
                console.log(e);
            }
        }
    };
};
