#!/usr/bin/perl -w

use strict;
use Socket qw(:DEFAULT :crlf);
use IO::Socket;
use lib('/opt/joden/lib');
use Joden;
use JSON;
use DateTime;

	my($_joden)   = Joden->new;
	my($_ip)      = '69.162.168.48';
	my($_port)    = 1988;
	my($_docroot) = '/opt/jsonsql';
	my($_json)    = JSON->new;
	my($_server)  = new IO::Socket::INET(
		Proto     => 'tcp', 
		LocalAddr => $_ip, 
		LocalPort => $_port, 
		Listen    => SOMAXCONN, 
		Reuse     => 1
	);

	while (my($_client) = $_server->accept) {
		$_client->autoflush(1);
			
			my(%_request) = ();
			my(%_data);
			
			{
				local $/ = Socket::CRLF;

				while (<$_client>) {
					chomp;
	
					if (/\s*(\w+)\s*([^\s]+)\s*HTTP\/(\d.\d)/) {
						$_request{METHOD}       = uc($1);
						$_request{URL}          = $2;
						$_request{HTTP_VERSION} = $3;
					}
	
					elsif (/:/) {
						my($_type, $_val) = split(/:/, $_, 2);
						$_type            =~ s/^\s+//;
		
						foreach($_type, $_val) {
							s/^\s+//;
							s/\s+$//;
						}
	
						$_request{lc($_type)} = $_val;
					}
	
					elsif (/^$/) {
						read($_client, $_request{CONTENT}, $_request{'content-length'})
							if (defined($_request{'content-length'}));
						last;
					}
				}
			}
			
			if ($_request{METHOD} eq 'GET') {
				if ($_request{URL} =~ /(.*)\?(.*)/) {
					$_request{URL}     = $1;
					$_request{CONTENT} = $2;
				} else {
					%_data = ();
				}

				$_data{"_method"} = "GET";
			}

			elsif ($_request{METHOD} eq 'POST') {
				$_data{"_method"} = "POST";
			} else {
				$_data{"_method"} = "ERROR";
			}

			if ($_request{METHOD} eq 'GET') {
				print($_client "HTTP/1.0 200 OK", $CRLF);
				print($_client "Content-type: application/json", $CRLF);
				print($_client $CRLF);
				print($_client $_joden->parse($_request{CONTENT}));
					
					$_data{"_status"} = "200";
			}

			elsif ($_request{METHOD} eq 'POST') {
				print($_client "HTTP/1.0 200 OK", $CRLF);
				print($_client "Content-type:  application/json", $CRLF);
				print($_client $CRLF);
				print($_client $_joden->parse($_request{CONTENT}));
					
					$_data{"_status"} = "200";
			} else {
				print($_client "HTTP/1.0 200 OK", $CRLF);
				print($_client "Content-type:  application/json", $CRLF);
				print($_client $CRLF);
				print($_client '{"error":"No data.  Nothing to do."}');
				
					$_data{"_status"} = "404";
			}
		
		open(LOG, '>>/opt/jsonsql/logs/activity.log');
			my($_dt) = DateTime->now(
				time_zone => 'America/New_York'
			);
			
			print(LOG "REQUEST [".$_dt->mdy." ".$_dt->hms."]\n");
				
				while (my($_k, $_v) = each(%_request)) {
					print(LOG "[$_k] => $_v\n");
				}
			
			print(LOG "\nDATA [".$_dt->mdy." ".$_dt->hms."]\n");
			
				while (my($_k, $_v) = each(%_data)) {
					print(LOG "[$_k => $_v]\n");
				}
			
			print(LOG "\n\n");
		close(LOG);
		}
