#! /home/nikita/Robots/env/bin/python2
import random
import math
from sys import stderr
from rtb import Robot, RobotColours
from fuzzy.storage.fcl.Reader import Reader

system = Reader().load_from_file('rules.fcl')

def debug(message):
    stderr.write('D %s%s' % (message, '\n'))


in_data = {'Dist': 0.0, 'Type': 0.0, 'Speed': 0.0}
out_data = {'Speedup': 0.0, 'Agr': 0.0, 'Rotation': 0.0}

object_ids = {
    'cookie': 0,
    'wall': 1,
    'mine': 2,
    'robot': 3,
}

direction = random.choice((-1,1))

class MyRobot(Robot):
    def __init__(self, *args, **kwargs):
        self.speed = 0
        super(MyRobot, self).__init__(*args, **kwargs)

    def radar(self, distance, observed_object_type, radar_angle):
        # debug("distance " + str(distance))
        # debug("speed " + str(self.speed))
        in_data['Dist'] = distance
        in_data['Type'] = object_ids.get(observed_object_type, 0)
        in_data['Speed'] = self.speed * 10

        system.calculate(in_data, out_data)
        agr = out_data['Agr']
        speedup = out_data['Speedup'] - 1
        rotation = out_data['Rotation']
        #debug("in_data: " + str(in_data) + " action: " + str(out_data) + " act: %d %d %d" % (agr, speedup, rotation))
        if agr > 0.1:
            #debug("Shoot! " + str(agr))
            self.send_shoot(agr)

        if speedup < -0.1:
            debug("brake! " + str(speedup))
            self.send_brake()
        elif speedup < 0.1:
            self.send_accelerate(0)
            self.send_brake(0)
        else:
            self.send_accelerate(speedup)

        if rotation < 0.1:
            self.send_rotate(0, robot=True)
        else:
            #debug(str(out_data['Rotation']))
            self.send_rotate_amount(0.7, direction * rotation * math.pi / 4, robot=True)
        # if distance > 5:
        #     self.send_accelerate(0.5)
        #     self.send_rotate(0.2, robot=True)
        # else:
        #     self.send_rotate(0.6, robot=True)
        # if observed_object_type == 'robot':
        #     self.send_shoot(1)

    def info(self, time, speed, cannon_angle):
        self.speed = speed

if __name__ == '__main__':
    # We only create and start a robot if this script is runned as a main script
    my_robot = MyRobot("My Robot", RobotColours(first_choice='386273', second_choice='d97154'))
    my_robot.start()
