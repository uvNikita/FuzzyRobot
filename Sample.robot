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
        self.direction = random.choice((-1,1))
        self.change = random.random() * 10 + 10
        super(MyRobot, self).__init__(*args, **kwargs)

    def game_starts(self, *args, **kwargs):
        self.send_sweep(2, -RADAR_ANGLE, RADAR_ANGLE, radar=True)
        super(MyRobot, self).game_starts(*args, **kwargs)

    def radar(self, distance, observed_object_type, radar_angle):
        #debug("RA: {}".format(radar_angle))
        # if observed_object_type in {'robot', 'cookie'}:
        #     self.send_rotate(0, radar=True)
        #     self.send_rotate_amount(1, radar_angle, radar=True) # !! to radar
        # else:
        #     self.send_sweep(0.8, -RADAR_ANGLE, RADAR_ANGLE, radar=True)
        in_data['Dist'] = distance
        in_data['Type'] = object_ids.get(observed_object_type, 0)
        in_data['Speed'] = self.speed
        in_data['Angle'] = radar_angle / RADAR_ANGLE

        fuzzy.calculate(in_data, out_data)
        agr = out_data['Agr']
        speedup = out_data['Speedup']
        rotation = out_data['Rotation']
        debug("in_data: " + str(in_data) + " action: " + str(out_data) + " act: %d %d %d" % (agr, speedup, rotation))
        if agr > 0.1:
            #debug("Shoot! " + str(agr))
            self.send_shoot(agr)

        #debug("speedup: {}".format(speedup))
        if speedup < 0:
            # debug("brake! " + str(speedup))
            self.send_brake(-speedup)
            self.send_accelerate(0)
        else:
            self.send_brake(0)
            self.send_accelerate(speedup)

        #debug("Rotation {}".format(rotation))

        if -0.05 < rotation < 0.05:
            self.send_rotate(0, robot=True)
        else:
            self.send_rotate(rotation, robot=True)

    def info(self, time, speed, cannon_angle):
        self.speed = speed
        if time > self.change:
            debug("Changed!!")
            debug("speed: {}".format(self.speed))
            self.direction = random.choice((-1,1))
            self.change += random.random() * 10 + 10
        # debug("Time: {}".format(time))

    # def rotation_reached(self, what_has_reached):
    #     debug("rotated!")
    #     if what_has_reached == 'radar':
    #         self.radar_direction = -self.radar_direction
    #         self.send_rotate_amount(1, self.radar_direction * math.pi / 4, radar=True)

if __name__ == '__main__':
    my_robot = MyRobot("My Robot", RobotColours(first_choice='386273',
                                                second_choice='d97154'))
    my_robot.start()
