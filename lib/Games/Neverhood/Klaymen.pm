package Games::Neverhood;
use 5.01;
use strict;
use warnings;

use Games::Neverhood::Holder;

our $Klaymen = Games::Neverhood::Holder->new(
	folder => 'klaymen',
	sprite => 'snore',
	on_ground => 1,
	snore => {
		frames => 35,
		offset => [-103, 3],
		sequences => [
			[ 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31, 32, 32, 33, 33, 34, 34, 34 ]
		],
		events => { 0 => sub { $_[0]->sprite_name = 'wake' if $_[2] } },
	},
	wake => {
		frames => 62,
		offset => [-106, 8],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31, 32, 32, 33, 33, 34, 34, 35, 35, 36, 36, 36, 36, 36, 37, 37, 37, 37, 37, 37, 38, 38, 38, 38, 38, 38, 39, 39, 39, 40, 40, 40, 40, 39, 39, 39, 36, 36, 36, 36, 37, 37, 37, 37, 38, 38, 38, 38, 39, 39, 39, 40, 40, 40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47, 48, 48, 49, 50, 50, 51, 51, 52, 52, 53, 53, 54, 54, 55, 55, 56, 56, 57, 57, 58, 58, 59, 59, 60, 60, 61, 61 ]
		],
		events => { 0 => sub { $_[0]->sprite_name = 'idle' if $_[2] } },
	},
	idle => {
		frames => 7,
		offset => [-40, 0],
		sequences => [
			[ 0, 0, 1, 1, 2, 2 ],
			[ 3, 3, 4, 5, 5, 6, 6 ],
		],
		events => {
			0 => sub { $_[0]->sequence_num = 1 if $Games::Neverhood::M{blink} },
			# 1 => sub { $_[0]->sequence_num = 0 if $_[2] },
			1 => sub { $_[0]->sprite_name = 'idle_random_0' if $_[2] },
		},
	},
	idle_random_0 => {
		frames => 77,
		offset => [-60, 1],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 13, 14, 15, 16, 16, 17, 18, 18, 19, 19, 19, 19, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 27, 27, 28, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 33, 34, 35, 36, 37, 38, 39, 40, 41, 43, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 54, 54, 54, 54, 54, 55, 55, 55, 55, 55, 55, 56, 56, 57, 57, 58, 58, 59, 59, 60, 60, 61, 61, 62, 62, 63, 63, 64, 64, 65, 65, 66, 66, 67, 67, 68, 68, 69, 69, 70, 71, 71, 72, 72, 73, 73, 74, 74, 75, 75, 76, 76 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'idle_random_1' if $_[2] } },
	},
	idle_random_1 => {
		frames => 103,
		offset => [-93, 0],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 25, 26, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31, 32, 33, 33, 34, 34, 35, 35, 36, 36, 37, 37, 38, 38, 39, 39, 40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 44, 45, 45, 46, 46, 47, 47, 48, 48, 49, 49, 50, 50, 51, 51, 52, 52, 53, 53, 54, 54, 55, 55, 56, 56, 57, 57, 58, 58, 59, 59, 60, 60, 61, 61, 61, 62, 62, 63, 64, 64, 65, 65, 66, 66, 67, 67, 68, 68, 69, 69, 70, 70, 71, 71, 72, 72, 73, 73, 74, 74, 75, 75, 76, 76, 77, 77, 78, 78, 79, 79, 80, 80, 81, 81, 82, 82, 83, 83, 84, 84, 85, 85, 86, 86, 87, 87, 88, 88, 89, 89, 90, 90, 91, 91, 86, 86, 92, 92, 93, 94, 94, 95, 95, 96, 96, 97, 97, 98, 98, 99, 99, 100, 100, 101, 101, 102, 102 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'idle_random_2' if $_[2] } },
	},
	idle_random_2 => {
		frames => 59,
		offset => [-80, 1],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 10, 10, 11, 11, 12, 12, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 23, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 23, 23, 24, 24, 30, 31, 31, 32, 32, 33, 33, 34, 34, 35, 35, 36, 36, 34, 34, 35, 35, 36, 36, 34, 34, 35, 35, 36, 36, 34, 34, 35, 35, 36, 36, 37, 37, 38, 38, 39, 39, 40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47, 45, 45, 46, 46, 48, 48, 49, 50, 50, 51, 51, 45, 45, 46, 46, 47, 47, 45, 45, 46, 46, 47, 47, 45, 45, 46, 46, 47, 47, 48, 48, 49, 49, 50, 50, 51, 51, 52, 52, 52, 52, 52, 53, 53, 54, 54, 55, 55, 56, 56, 57, 57, 58, 58 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'idle_random_3' if $_[2] } },
	},
	idle_random_3 => {
		frames => 73,
		offset => [-82, 0],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31, 32, 32, 33, 33, 34, 34, 35, 35, 36, 36, 36, 36, 36, 36, 36, 36, 37, 37, 38, 38, 39, 39, 40, 40, 41, 41, 42, 42, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 45, 46, 47, 48, 49, 50, 46, 47, 49, 50, 47, 49, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 51, 52, 53, 54, 54, 50, 51, 52, 53, 54, 54, 50, 51, 52, 53, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 46, 47, 48, 49, 50, 46, 46, 48, 48, 49, 49, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 51, 52, 53, 54, 54, 50, 51, 52, 53, 54, 54, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 56, 56, 57, 57, 58, 58, 59, 59, 60, 60, 61, 61, 62, 62, 63, 63, 64, 64, 65, 65, 66, 66, 67, 67, 68, 68, 69, 69, 70, 71, 71, 72, 72 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'idle_random_4' if $_[2] } },
	},
	idle_random_4 => {
		frames => 138,
		offset => [-90, 1],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31, 32, 32, 33, 33, 34, 34, 35, 35, 36, 36, 37, 37, 38, 38, 39, 39, 40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47, 48, 48, 49, 49, 50, 50, 51, 51, 52, 52, 53, 53, 54, 55, 55, 56, 56, 57, 57, 58, 58, 59, 59, 60, 60, 61, 61, 62, 62, 63, 63, 64, 64, 65, 65, 66, 66, 67, 67, 68, 68, 69, 69, 70, 70, 71, 71, 72, 72, 73, 73, 74, 74, 75, 75, 76, 76, 77, 77, 78, 78, 79, 79, 80, 80, 81, 81, 82, 82, 83, 83, 84, 84, 85, 86, 86, 87, 87, 88, 88, 89, 89, 90, 90, 91, 91, 92, 92, 93, 93, 94, 94, 95, 95, 96, 96, 97, 97, 98, 98, 99, 99, 100, 100, 101, 101, 102, 102, 103, 103, 103, 103, 104, 104, 104, 104, 105, 105, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111, 111, 112, 112, 113, 113, 114, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 120, 121, 121, 122, 122, 123, 123, 124, 124, 125, 125, 126, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 132, 119, 119, 120, 120, 121, 121, 122, 122, 123, 123, 124, 124, 125, 125, 126, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 132, 132, 132, 132, 132, 132, 132, 133, 133, 134, 134, 135, 135, 136, 136, 137, 137 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'think' if $_[2] } },
	},
	think => {
		frames => 22,
		offset => [-63, 1],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 8, 8, 9, 9, 10, 10, 8, 8, 9, 9, 10, 10, 8, 8, 9, 10, 10, 11, 11, 12, 12, 13, 13, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 8, 8, 9, 9, 10, 10, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'pull_lever' if $_[2] } },
	},
	pull_lever => {
		frames => 32,
		offset => [-77, 0],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 16, 16, 15, 15, 14, 14, 13, 13, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 31, 31 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'push_button_back' if $_[2] } },
	},
	push_button_back => {
		frames => 54,
		offset => [-61, 2],
		sequences => [
			[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 9, 9, 10, 10, 11, 12, 13, 13, 14, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22, 23, 24, 25, 26, 26, 27, 28, 28, 29, 30, 30, 31, 31, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34, 35, 35, 36, 36, 37, 37, 38, 38, 39, 39, 40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47, 48, 48, 49, 49, 50, 51, 51, 52, 53, 53 ],
		],
		events => { 0 => sub { $_[0]->sprite_name = 'idle' if $_[2] } },
	},
);

1;
