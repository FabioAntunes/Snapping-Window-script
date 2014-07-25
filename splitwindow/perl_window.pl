#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
#Get Active Window ID
#active_window=`xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2`;
#Since xprop returns a different hexadecimal for example "0x460001e"
#we need to transform it in "0x0460001e"
#active_window=${active_window/0x/0x0}

#wmctrl list is in order with newly opened windows appearing at the bottom

#my $active_window=`wmctrl -l | tail -1 | cut -d' ' -f1 `;


#Get Active window info
my $window = get_active_window_info();

#-----------------DEBUG var_dump func---------
#print Dumper($active_window_info);

my $monitors = get_monitors();
 
#my $command = `wmctrl -r :ACTIVE: -e 0,0,0,960,1080`;

my $half_width;
my $command;

my $orientation = $ARGV[0];

if($orientation eq "left")
{
	move_left();
}elsif($orientation eq "right")
{

}


sub get_active_window_info
{
	# my $command_result = `xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2`;
	my $command_result = `xprop -root 32x _NET_ACTIVE_WINDOW | grep -o "[0-9]x[0-9]*"`;
	$command_result =~ s/0x/0x0/g;
	my $active_window_id = $command_result;
	
	$command_result = `wmctrl -lG | grep $active_window_id`;
	my @array = split(' ', $command_result);
	$command_result =`xwininfo -id $active_window_id`;
    my %window_info=();

    $window_info{ 'id' } = $active_window_id; 
    $window_info{ 'desktop' } = $array[1]; 
	my @matches = $command_result =~ /Width:\s*([0-9]*)/;
    $window_info{ 'width' } = $matches[0]; 
	@matches = $command_result =~ /Height:\s*([0-9]*)/;
    $window_info{ 'height' } = $matches[0]; 

    #get window coordinates
	@matches = $command_result =~ /Relative upper-left X:\s*([0-9]*)/;
    $window_info{ 'x_rel' } = $matches[0];

	@matches = $command_result =~ /Relative upper-left Y:\s*([0-9]*)/;
    $window_info{ 'y_rel' } = $matches[0];
    
	@matches = $command_result =~ /Absolute upper-left X:\s*([0-9]*)/;
    $window_info{ 'x' } = $matches[0] - $window_info{ 'x_rel' }; 

	
	@matches = $command_result =~ /Absolute upper-left Y:\s*([0-9]*)/;
    $window_info{ 'y' } = $matches[0] - $window_info{ 'y_rel' }; 


    return \%window_info;
}

sub get_monitors
{
	my %monitors=();
 	my @command_result = `xrandr | grep -w "connected" | cut -d, -f2 | cut -d" " -f3 | grep .`;    
	chomp @command_result;

	foreach my $key (keys @command_result) {
	    my @matches = $command_result[$key] =~ /([0-9]*)x([0-9]*)\+([0-9]*)\+([0-9]*)/;


	    $monitors{ $key+1 }{'width'} = $matches[0];
	    $monitors{ $key+1 }{'height'} = $matches[1];
	    $monitors{ $key+1 }{'x'} = $matches[2];
	    $monitors{ $key+1 }{'y'} = $matches[3];
	    
 	}
 	return \%monitors;
}

sub move_left
{
	if($window->{'x'} >= $monitors->{1}->{'x'} &&  $window->{'x'}<=($monitors->{1}->{'width'}+$monitors->{1}->{'x'}))
	{
		$half_width = $monitors->{1}->{'width'}/2;
		
		$command = `wmctrl -r :ACTIVE: -b remove,stick,fullscreen`;
		$command = `wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz`;
		$command = `wmctrl -r :ACTIVE: -e 0,$monitors->{1}->{'x'},0,$half_width,$monitors->{1}->{'height'}`;
		$command = `wmctrl -r :ACTIVE: -b add,maximized_vert`;

	}elsif($window->{'x'} >= $monitors->{2}->{'x'} &&  $window->{'x'}<=($monitors->{2}->{'width'}+$monitors->{2}->{'x'})){
		$half_width = $monitors->{2}->{'width'}/2;
		
		$command = `wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz`;
		$command = `wmctrl -r :ACTIVE: -b remove,stick,fullscreen`;
		$command = `wmctrl -r :ACTIVE: -e 0,$monitors->{2}->{'x'},0,$half_width,$monitors->{2}->{'height'}`;
		$command = `wmctrl -r :ACTIVE: -b add,maximized_vert`;
		
	}
}