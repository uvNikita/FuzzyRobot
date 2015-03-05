#!/usr/bin/env python

import os.path
import random
import math
from sys import stderr

from rtb import Robot, RobotColours
from fuzzy.storage.fcl.Reader import Reader


__location__ = os.path.dirname(os.path.realpath(__file__))


fuzzy = Reader().load_from_file(os.path.join(__location__, 'rules.fcl'))


def debug(message):
    stderr.write('Debug: {}\n'.format(message))


object_ids = {
    'cookie': 0,
    'wall': 1,
    'mine': 2,
    'robot': 3,
}

RADAR_ANGLE = math.pi / 4


class MyRobot(Robot):
    def __init__(self, *args, **kwargs):
        self.speed = 0
        self.is_rotating = False
        super(MyRobot, self).__init__(*args, **kwargs)

    def initialize(self, *args, **kwargs):
        self.send_option("send_rotation_reached", "rotate_finished")
        super(MyRobot, self).initialize(*args, **kwargs)

    def game_starts(self, *args, **kwargs):
        self.send_sweep(1, -RADAR_ANGLE, RADAR_ANGLE, radar=True)
        super(MyRobot, self).game_starts(*args, **kwargs)

    def radar(self, distance, observed_object_type, radar_angle):
        if observed_object_type in {'robot', 'cookie'}:
            self.send_rotate_amount(1, radar_angle, robot=True)
            self.send_rotate_amount(1, -radar_angle, radar=True)
        elif not self.is_rotating:
            self.send_sweep(1, -RADAR_ANGLE, RADAR_ANGLE, radar=True)

        in_data = {
            'Dist': 0.0,
            'Type': 0.0,
            'Speed': 0.0,
            'Angle': 0.0,
        }

        out_data = {
            'Speedup': 0.0,
            'Agr': 0.0,
            'Rotation': 0.0,
        }

        in_data['Dist'] = distance
        in_data['Type'] = object_ids.get(observed_object_type, 1)
        in_data['Speed'] = self.speed
        in_data['Angle'] = radar_angle / RADAR_ANGLE

        fuzzy.calculate(in_data, out_data)
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

        if not self.is_rotating:
            self.send_rotate_amount(0.8, rotation * math.pi / 2, robot=True)
            self.is_rotating = True

    def info(self, time, speed, cannon_angle):
        self.speed = speed

    def rotation_reached(self, what_has_reached):
        self.is_rotating = False

if __name__ == '__main__':
    my_robot = MyRobot("My Robot", RobotColours(first_choice='386273',
                                                second_choice='d97154'))
    my_robot.start()
