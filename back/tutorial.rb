#!/usr/bin/ruby -w

a = 1;
b = 2;

puts a + b;

puts "lol ruby";

print <<EOF
	Hello lol
EOF

BEGIN {
print 1 + 1;
print "\n";
}

END {

print "HAHAHAHA OK\n";

}

=begin

lol comment daw to

=end
