# Games::Neverhood::ResourceKey - Just a class holding a string. See Games::Neverhood::Exports::Declare
# Copyright (C) 2012 Blaise Roth

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.01;
use strict;
use warnings;

package Games::Neverhood::ResourceKey;

use overload
	'""' => sub { ${+shift} },
	fallback => 1,
;

sub new {
	my ($class, $key) = @_;
	bless \$key, $class;
}

1;
