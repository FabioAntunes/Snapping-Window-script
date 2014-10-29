#!/usr/bin/perl -w
use strict;
use warnings;
use POSIX;
use Data::Dumper;
#-----------------DEBUG var_dump func---------
#print Dumper($active_window_info);


#Get Active window info
my $window = get_active_window_info();
#This will store a copy of the active window info
my $active_window_copy;
#Get monitors info
my $monitors = get_monitors();
#This will be the half width of the monitor where the active window is
my $half_width;
#This will be the half height of the monitor where the active window is
my $half_height;
#This will be x coordinate representing a quarter of the monitor where the active window is
my $quarter_x;
#This will be y coordinate representing a quarter of the monitor where the active window is
my $quarter_y;
#This will store the commands we need to run
my $command;
#This is the orientation passed to the perl script, so we can know if we want to move the window to the right or to the left
my $orientation = $ARGV[0];

if($orientation eq "left")
{
	move_left();
	
}elsif($orientation eq "right")
{
	move_right();
}

#Function that will get active window info.
#Returns an array
sub get_active_window_info
{
	#We must run xprop to get the active window
	my $command_result = `xprop -root 32x _NET_ACTIVE_WINDOW | grep -o "[0-9]x[0-9].*"`;
	#The id of the active window that Xprop returns is different from the id of wmctrl, it misses a "0" so we must replace "0x" with "0x0"
	$command_result =~ s/0x/0x0/g;
	my $active_window_id = $command_result;
	
	$command_result = `wmctrl -lG | grep $active_window_id`;
	my @array = split(' ', $command_result);
	$command_result =`xwininfo -id $active_window_id`;
    my %window_info=();

    #Get and parse active window info
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

#Function that will get active window info.
#Returns a Hash
sub get_monitors
{
	my %monitors=();
	#We must use xrandr command so we can get info about the connected displays
 	my @command_result = `xrandr | grep -w "connected" | cut -d, -f2 | cut -d" " -f3 | grep .`;    
	chomp @command_result;

	#Store monitor info into a hash map
	foreach my $key (keys @command_result) {
	    my @matches = $command_result[$key] =~ /([0-9]*)x([0-9]*)\+([0-9]*)\+([0-9]*)/;


	    $monitors{ $key+1 }{'width'} = $matches[0];
	    $monitors{ $key+1 }{'height'} = $matches[1];
	    $monitors{ $key+1 }{'x'} = $matches[2];
	    $monitors{ $key+1 }{'y'} = $matches[3];
	    
 	}
 	return \%monitors;
}

#Function that will move window to the left side of the monitor or move it to the monitor on the left
sub move_left
{
	if($window->{'x'} >= $monitors->{1}->{'x'} &&  $window->{'x'}<($monitors->{1}->{'width'}+$monitors->{1}->{'x'}))
	{
		$half_width = ceil($monitors->{1}->{'width'}/2)-$window->{'x_rel'}-$window->{'x_rel'};
		cmd_resize_window(1, $monitors->{1}->{'x'});
		transfer_left(2);

	}elsif($window->{'x'} >= $monitors->{2}->{'x'} &&  $window->{'x'}<($monitors->{2}->{'width'}+$monitors->{2}->{'x'})){
		$half_width = ceil($monitors->{2}->{'width'}/2)-$window->{'x_rel'}-$window->{'x_rel'};
		cmd_resize_window(1, $monitors->{2}->{'x'});
		transfer_left(1);
		
	}
}
#Function that will move window to the right side of the monitor or move it to the monitor on the right
sub move_right
{
	if($window->{'x'} >= $monitors->{1}->{'x'} &&  $window->{'x'}<($monitors->{1}->{'width'}+$monitors->{1}->{'x'}))
	{
		$half_width = ceil($monitors->{1}->{'width'}/2);
		my $x = ceil($half_width + $monitors->{1}->{'x'} + $window->{'x_rel'}*2);

		cmd_resize_window(1, $x);
		transfer_right(2);

	}elsif($window->{'x'} >= $monitors->{2}->{'x'} &&  $window->{'x'}<($monitors->{2}->{'width'}+$monitors->{2}->{'x'})){
		$half_width = ceil($monitors->{2}->{'width'}/2);
		my $x = ceil($half_width + $monitors->{2}->{'x'} + $window->{'x_rel'}*2);

		cmd_resize_window(2, $x);
		transfer_right(1);
		
	}
}

sub transfer_left{
	if($window->{'x'} >= $monitors->{$_[0]}->{'width'}+$monitors->{$_[0]}->{'x'} && is_window_same_state()){
		cmd_transfer_window($_[0]);
	}

}

sub transfer_right{
	if($window->{'x'} < $monitors->{$_[0]}->{'width'}+$monitors->{$_[0]}->{'x'} && is_window_same_state() ){
		cmd_transfer_window($_[0]);
	}

}

#Function that executes wmctrl and resizes the window to half the width of the current monitor
sub cmd_resize_window
{
	$command = `wmctrl -r :ACTIVE: -b remove,stick,fullscreen`;
	$command = `wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz`;
	$command = `wmctrl -r :ACTIVE: -e 0,$_[1],0,$half_width,$monitors->{$_[0]}->{'height'}`;
	$command = `wmctrl -r :ACTIVE: -b add,maximized_vert`;

	#Get active window info after the resize
	$active_window_copy = get_active_window_info;
}
sub cmd_transfer_window{
	$half_width = ceil($monitors->{$_[0]}->{'width'}/2 - $window->{'x_rel'}*2);
	$half_height = ceil($monitors->{$_[0]}->{'height'}/2 - $window->{'y_rel'}*2);
	$quarter_y = ceil($monitors->{$_[0]}->{'height'}/4 + $monitors->{$_[0]}->{'y'});
	$quarter_x = ceil($monitors->{$_[0]}->{'width'}/4 + $monitors->{$_[0]}->{'x'});
	$command = `wmctrl -r :ACTIVE: -b remove,stick,fullscreen`;
	$command = `wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz`;
	$command = `wmctrl -r :ACTIVE: -e 0,$quarter_x,$quarter_y,$half_width,$half_height`;
}

#Function that checks if window is at the same state, so we know if we must transfer the window the another monitor
sub is_window_same_state{
	if($active_window_copy->{'y_rel'} eq $window->{'y_rel'} &&
			$active_window_copy->{'x_rel'} eq $window->{'x_rel'} &&
			$active_window_copy->{'height'} eq $window->{'height'} &&
			$active_window_copy->{'desktop'} eq $window->{'desktop'} &&
			$active_window_copy->{'id'} eq $window->{'id'} &&
			$active_window_copy->{'x'} eq $window->{'x'} &&
			$active_window_copy->{'y'} eq $window->{'y'} )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}
