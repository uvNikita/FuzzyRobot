#!/usr/bin/env python

import os.path
import random
import math
from sys import stderr

from rtb import Robot, RobotColours
from fuzzy.storage.fcl.Reader import Reader


__location__ = os.path.dirname(os.path.realpath(__file__))


# initialize fuzzy logic engine
fuzzy = Reader().load_from_file(os.path.join(__location__, 'example_rules.fcl'))


def debug(message):
    """Helper function to display debug message in console"""
    stderr.write('Debug: {}\n'.format(message))

object_ids = {
    'cookie': 0,
    'wall': 1,
    'mine': 2,
    'robot': 3,
}

class MyRobot(Robot):
    def __init__(self, *args, **kwargs):
        # used to store robot speed from the previous state
        self.speed = 0
        super(MyRobot, self).__init__(*args, **kwargs)

    def radar(self, distance, observed_object_type, radar_angle):
        """Will be called 'radar' event occur
        distance : distance to object
        observed_object_type :
            can be one of {'noobject', 'robot', 'shot', 'wall', 'cookie', 'mine'}
        radar_angle : angle of the radar with respect to the robot body in radians"""

        # input data for fuzzy logic engine
        in_data = {
            'Dist': 0.0,  # distance to object
            'Type': 0.0,  # type of object with order of 'aggression'
            'Speed': 0.0,  # current speed of robot
        }

        # output data from fuzzy logic engine
        out_data = {
            'Speedup': 0.0,  # shows how much the robot must accelerate
            'Agr': 0.0,  # shows the aggresssion of robot
            'Rotation': 0.0,  # amount to rotate
        }

        in_data['Dist'] = distance
        in_data['Type'] = object_ids.get(observed_object_type, 1)
        in_data['Speed'] = self.speed

        # perform fuzzy logic calculations on given rules
        fuzzy.calculate(in_data, out_data)

        # get all calculated information
        agr = out_data['Agr']
        speedup = out_data['Speedup']
        rotation = out_data['Rotation']

        # shoot with calculated aggression
        self.send_shoot(agr)

        # if calculated speedup is negative, then robot should brake, accelerate in other case
        if speedup < 0:
            self.send_brake(-speedup)
            self.send_accelerate(0)
        else:
            self.send_brake(0)
            self.send_accelerate(speedup)

        self.send_rotate_amount(0.8, rotation * math.pi / 3, robot=True)

    def info(self, time, speed, cannon_angle):
        # save current robot speed to use it in radar function
        self.speed = speed

if __name__ == '__main__':
    my_robot = MyRobot("Example Robot", RobotColours(first_choice='386273',
                                                     second_choice='d97154'))
    my_robot.start()
