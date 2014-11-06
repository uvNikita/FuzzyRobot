# coding: utf-8

"""
Codebase is taken from:
https://github.com/cGuille/python-realtimebattle-api
"""

# When you send messages to RealTimeBattle make shure that they are not longer than 128 chars,
# otherwise RealTimeBattle will cut them in two parts and may report an unknown message.

import sys
from collections import namedtuple

RobotColours = namedtuple('RobotColours', ['first_choice', 'second_choice'])

class RobotInfoListener(object):
	# Here are all the method you can overload in order to get your robot info:
	def initialize(self, first):
		self.unhandled(get_caller_name())
	def game_starts(self):
		self.unhandled(get_caller_name())
	def info(self, time, speed, cannon_angle):
		self.unhandled(get_caller_name())
	def radar(self, distance, observed_object_type, radar_angle):
		self.unhandled(get_caller_name())
	def coordinates(self, x, y, angle):
		self.unhandled(get_caller_name())
	def energy(self, energy_level):
		self.unhandled(get_caller_name())
	def collision(self, colliding_object, angle_relative_robot):
		self.unhandled(get_caller_name())
	def robot_info(self, energy_level, teammate):
		self.unhandled(get_caller_name())
	def rotation_reached(self, what_has_reached):
		self.unhandled(get_caller_name())
	def robots_left(self, number_of_robots):
		self.unhandled(get_caller_name())
	def dead(self):
		self.unhandled(get_caller_name())
	def game_finishes(self):
		self.unhandled(get_caller_name())
	def exit_robot(self):
		self.unhandled(get_caller_name())
	def game_option(self, optionnr, value):
		self.unhandled(get_caller_name())
	def your_name(self, name):
		self.unhandled(get_caller_name())
	def your_colour(self, colour):
		self.unhandled(get_caller_name())
	def warning(self, warning_type, message):
		self.unhandled(get_caller_name())
	def unhandled(self, name): pass

	def __init__(self):
		self.run = False

	def is_running(self):
		return self.run

	def start(self):
		self.run = True
		while self.run:
			try:
				command_line = sys.stdin.readline().split()
			except IOError as error:
				sys.stderr.write(str(error))
			except:
				sys.stderr.write("Unexpected error: %s" % str(sys.exc_info()[0]))
			else:
				command = command_line.pop(0)
				if command == "RobotInfo":# is teammate given (since it seems the team mode is not implemented)?
					self.robot_info(
						energy_level=float(command_line[0]),
						teammate=True if int(command_line[1]) == 1 else False
					)
				elif command == "Coordinates":
					self.coordinates(*map(float, command_line))
				elif command == "Info":
					self.info(
						time=float(command_line[0]), 
						speed=float(command_line[1]),
						cannon_angle=float(command_line[2])
					)
				elif command == "Radar":
					self.radar(
						distance=float(command_line[0]),
						observed_object_type=str(reverse_object_types[int(command_line[1])]),
						radar_angle=float(command_line[2])
					)
				elif command == "RotationReached":
					# TODO: transform into "robot", "cannon" or "radar" accordingly
					self.rotation_reached(what_has_reached=int(command_line[0]))
				elif command == "Energy":
					self.energy(energy_level=float(command_line[0]))
				elif command == "RobotsLeft":
					self.robots_left(number_of_robots=int(command_line[0]))
				elif command == "Collision":
					self.collision(
						colliding_object=reverse_object_types[int(command_line[0])],
						angle_relative_robot=float(command_line[1])
					)
				elif command == "Warning":
					self.warning(
						warning_type=str(reverse_warning_types[int(command_line[0])]),
						message='' if len(command_line) == 1 else str(command_line[1])
					)
				elif command == "GameStarts":
					self.game_starts()
				elif command == "GameOption":
					self.game_option(optionnr=int(command_line[0]), value=float(command_line[1]))
				elif command == "YourName":
					self.your_name(name=str(command_line[0]))
				elif command == "YourColour":
					self.your_colour(colour=str(command_line[0]))
				elif command == 'Initialize':
					self.initialize(first=int(command_line[0]) == 1)
				elif command == "Dead":
					self.dead()
				elif command == "GameFinishes":
					self.game_finishes()
				elif command == 'ExitRobot':
					self.run = False
					self.exit_robot()

class RobotActuator(object):
	def send_name(self, name):
		"""Send the message `Name [name (string)]`"""
		send("Name %s" % (name))

	def send_colour(self, colours):
		"""Send the message `Colour [home colour (hex)] [away colour (hex)]`"""
		send("Colour %s %s" % colours)

	def send_option(self, option_name, value_name):
		"""Send the message `RobotOption [option nr (int)] [value (int)]`"""
		option			= robot_options[option_name]
		option_value	= robot_option_values[option_name][value_name]

		send("RobotOption %d %d" % (option, option_value))

	def send_rotate(self, angular_velocity, **kwargs):
		"""
		angular_velocity (double): given in radians per second

		Set the 'robot', 'cannon' and/or 'radar' keywords arguments to True to 
		specify which pieces of the robot must rotate.

		Send the message `Rotate [what to rotate (int)] [angular velocity (double)]`
		"""
		items = sum_given_items(all_item_values, kwargs)
		send("Rotate %d %f" % (items, angular_velocity))

	def send_rotate_to(self, angular_velocity, end_angle, **kwargs):
		"""
		angular_velocity (double): given in radians per second
		end_angle (double): given in radians

		Set the 'cannon' and/or 'radar' keywords arguments to True to specify 
		which pieces of the robot must rotate.

		Send the message `RotateTo [what to rotate (int)] [angular velocity (double)] [end angle (double)]`
		"""
		items = sum_given_items(robot_item_values, kwargs)
		send("RotateTo %d %f %f" % (items, angular_velocity, end_angle))

	def send_rotate_amount(self, angular_velocity, angle, **kwargs):
		"""
		angular_velocity (double): given in radians per second
		end_angle (double): given in radians

		Set the 'robot', 'cannon' and/or 'radar' keywords arguments to True to 
		specify which pieces of the robot must rotate.

		Will rotate relative to the current angle.
		Send the message `RotateAmount [what to rotate (int)] [angular velocity (double)] [angle (double)]`
		"""
		items = sum_given_items(all_item_values, kwargs)
		send("RotateAmount %d %f %f" % (items, angular_velocity, angle))

	def send_sweep(self, angular_velocity, right_angle, left_angle, **kwargs):
		"""Send the message `Sweep [what to rotate (int)] [angular velocity (double)] [right angle (double)] [left angle (double)]`"""
		items = sum_given_items(robot_item_values, kwargs)
		send("Sweep %d %f %f %f" % (items, angular_velocity, right_angle, left_angle))

	def send_accelerate(self, value):
		"""Send the message `Accelerate [value (double)]`"""
		send("Accelerate %f" % value)

	def send_brake(self, portion = 1.0):
		"""Send the message `Brake [portion (double)]`"""
		send("Brake %f" % portion)

	def send_shoot(self, shot_energy):
		"""Send the message `Shoot [shot energy (double)]`"""
		send("Shoot %f" % shot_energy)

	def send_message(self, message):
		"""Send the message `Print [message (string)]`"""
		send("Print %s" % message)

	def send_debug(self, message):
		"""Send the message `Debug [message (string)]`"""
		send("Debug %s" % message)

	def send_debug_line(self, angle1, radius1, angle2, radius2):
		"""Send the message `DebugLine [angle1 (double)] [radius1 (double)] [angle2 (double)] [radius2 (double)]`"""
		send("DebugLine %f %f %f %f" % (angle1, radius1, angle2, radius2))

	def send_debug_circle(self, center_angle, center_radius, circle_radius):
		"""Send the message `DebugCircle [center angle (double)] [center radius (double)] [circle radius (double)]`"""
		send("DebugCircle %f %f %f" % (center_angle, center_radius, circle_radius))


# You can get robot info by overriding RobotInfoListener methods.
# Look the RobotActuator methods to know what action your robot can send.
# If you wish to write your own __init__ or initialize method, do not
# forget to call the corresponding Robot method.
class Robot(RobotInfoListener, RobotActuator):
	def __init__(self, name, colours):
		super(RobotInfoListener, self).__init__()
		self.send_option('use_non_blocking', False)
		self.name = name
		self.colours = colours

	def initialize(self, first):
		if first is True:
			self.send_name(self.name)
			self.send_colour(self.colours)

# misc & data

def send(command):
	sys.stdout.write(command + '\n')
	sys.stdout.flush()

import inspect
def get_caller_name():
	return inspect.stack()[1][3]

object_types = {
  'noobject'		: -1,
  'robot'			: 0,
  'shot'			: 1,
  'wall'			: 2,
  'cookie' 			: 3,
  'mine'			: 4,
  'last_object_type': 5
}
reverse_object_types = dict((v, k) for k, v in object_types.items())

warning_types = {
  'unknown_message'					: 0,
  'process_time_low'				: 1,
  'message_sent_in_illegal_state'	: 2,
  'unknown_option'					: 3,
  'obsolete_keyword'				: 4,
  'name_not_given'					: 5,
  'colour_not_given'				: 6,
}
reverse_warning_types = dict((v, k) for k, v in warning_types.items())


all_item_values = {
	'robot' : 1,
	'cannon': 2,
	'radar' : 4
}
robot_item_values = all_item_values.copy()
del robot_item_values['robot']

def sum_given_items(item_values, kwargs):
	items_sum = 0
	for item, value in item_values.iteritems():
		if kwargs.get(item, False):
			items_sum += value
	return items_sum

robot_options = {
	'send_rotation_reached'	: 1,
	'use_non_blocking'		: 3
}

robot_option_values = {
	'send_rotation_reached': {
		'no_messages'	 : 0,
		'rotate_finished': 1, # messages when RotateTo and RotateAmount finished
		'rotate_sweep'	 : 2  # messages also when sweep direction is changed
	},
	'use_non_blocking' : { True: 1, False: 0 }
}

