#!/usr/bin/perl -w

#
#
# pf.pl (Stocks portfolio)
#
#use stock_data_access;
#
# Debugging
#
# database input and output is paired into the two arrays noted
#
my $debug=0; # default - will be overriden by a form parameter or cookie
my @sqlinput=();
my @sqloutput=();

#
# The combination of -w and use strict enforces various 
# rules that make the script more resilient and easier to run
# as a CGI script.
#
use strict;
use stock_data_access;

# The CGI web generation stuff
# This helps make it easy to generate active HTML content
# from Perl
#
# We'll use the "standard" procedural interface to CGI
# instead of the OO default interface
use CGI qw(:standard);



# The interface to the database.  The interface is essentially
# the same no matter what the backend database is.  
#
# DBI is the standard database interface for Perl. Other
# examples of such programatic interfaces are ODBC (C/C++) and JDBC (Java).
#
#
# This will also load DBD::Oracle which is the driver for
# Oracle.
use DBI;

#
#
# A module that makes it easy to parse relatively freeform
# date strings into the unix epoch time (seconds since 1970)
#
use Time::ParseDate;



#
# You need to override these for access to your database
#
my $dbuser="aly155";
my $dbpasswd="zaC43gcHq";


#
# The session cookie will contain the user's name and password so that 
# he doesn't have to type it again and again. 
#
# "RWBSession"=>"user/password"
#
# BOTH ARE UNENCRYPTED AND THE SCRIPT IS ALLOWED TO BE RUN OVER HTTP
# THIS IS FOR ILLUSTRATION PURPOSES.  IN REALITY YOU WOULD ENCRYPT THE COOKIE
# AND CONSIDER SUPPORTING ONLY HTTPS
#
my $cookiename="PortfolioSession";
#
# And another cookie to preserve the debug state
#
my $debugcookiename="PortfolioDebug";

#
# Get the session input and debug cookies, if any
#
my $inputcookiecontent = cookie($cookiename);
my $inputdebugcookiecontent = cookie($debugcookiename);

#
# Will be filled in as we process the cookies and paramters
#
my $outputcookiecontent = undef;
my $outputdebugcookiecontent = undef;
my $deletecookie=0;
my $user = undef;
my $password = undef;
my $logincomplain=0;

#
# Get the user action and whether he just wants the form or wants us to
# run the form
#
my $action;
my $run;


if (defined(param("postact"))) { 
  $action=param("postact");
  if (defined(param("run"))) { 
  $run = param("run") == 1;
  } else {
    $run = 0;
  }
}elsif (defined(param("act"))) { 
    $action=param("act");
    if (defined(param("run"))) { 
      $run = param("run") == 1;
    } else {
      $run = 0;
    }
}else{
    $action="base";
    $run = 1;
}




my $dstr;

if (defined(param("debug"))) { 
  # parameter has priority over cookie
  if (param("debug") == 0) { 
    $debug = 0;
  } else {
    $debug = 1;
  }
} else {
  if (defined($inputdebugcookiecontent)) { 
    $debug = $inputdebugcookiecontent;
  } else {
    # debug default from script
  }
}

$outputdebugcookiecontent=$debug;

#
#
# Who is this?  Use the cookie or anonymous credentials
#
#
if (defined($inputcookiecontent)) { 
  # Has cookie, let's decode it
  ($user,$password) = split(/\//,$inputcookiecontent);
  $outputcookiecontent = $inputcookiecontent;
} else {
  # No cookie, treat as anonymous user
  ($user,$password) = ("anon","anonanon");
}

#
# Is this a login request or attempt?
# Ignore cookies in this case.
#
if ($action eq "login") { 
  if ($run) { 
    #
    # Login attempt
    #
    # Ignore any input cookie.  Just validate user and
    # generate the right output cookie, if any.
    #
    ($user,$password) = (param('user'),param('password'));
    if (ValidUser($user,$password)) { 
      # if the user's info is OK, then give him a cookie
      # that contains his username and password 
      # the cookie will expire in one hour, forcing him to log in again
      # after one hour of inactivity.
      # Also, land him in the base query screen
      $outputcookiecontent=join("/",$user,$password);
      $action = "base";
      $run = 1;
    } else {
      # uh oh.  Bogus login attempt.  Make him try again.
      # don't give him a cookie
      $logincomplain=1;
      $action="login";
      $run = 0;
    }
  } else {
    #
    # Just a login screen request, but we should toss out any cookie
    # we were given
    #
    undef $inputcookiecontent;
    ($user,$password)=("anon","anonanon");
  }
} 


#
# If we are being asked to log out, then if 
# we have a cookie, we should delete it.
#
if ($action eq "logout") {
  $deletecookie=1;
  $action = "base";
  $user = "anon";
  $password = "anonanon";
  $run = 1;
}


my @outputcookies;

#
# OK, so now we have user/password
# and we *may* have an output cookie.   If we have a cookie, we'll send it right 
# back to the user.
#
# We force the expiration date on the generated page to be immediate so
# that the browsers won't cache it.
#
if (defined($outputcookiecontent)) { 
  my $cookie=cookie(-name=>$cookiename,
        -value=>$outputcookiecontent,
        -expires=>($deletecookie ? '-1h' : '+1h'));
  push @outputcookies, $cookie;
} 
#
# We also send back a debug cookie
#
#
if (defined($outputdebugcookiecontent)) { 
  my $cookie=cookie(-name=>$debugcookiename,
        -value=>$outputdebugcookiecontent);
  push @outputcookies, $cookie;
}

#
# Headers and cookies sent back to client
#
# The page immediately expires so that it will be refetched if the
# client ever needs to update it
#
print header(-expires=>'now', -cookie=>\@outputcookies);

#
# Now we finally begin generating back HTML
#
#
#print start_html('Red, White, and Blue');
print "<html style=\"height: 100\%\">";
print "<head>";
print "<title>Portfolio</title>";
print "</head>";

print "<body style=\"height:100\%;margin:0\">";

#
# Force device width, for mobile phones, etc
#
#print "<meta name=\"viewport\" content=\"width=device-width\" />\n";

# This tells the web browser to render the page in the style
# defined in the css file
#
#print "<style type=\"text/css\">\n\@import \"portfolio.css\";\n</style>\n";
  
print "<!-- Latest compiled and minified CSS -->
<link rel=\"stylesheet\" href=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">

<!-- jQuery library -->
<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js\"></script>

<!-- Latest compiled JavaScript -->
<script src=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>";
print "<center>" if !$debug;


#
#
# The remainder here is essentially a giant switch statement based
# on $action. 
#
#
#


# LOGIN
#
# Login is a special case since we handled running the filled out form up above
# in the cookie-handling code.  So, here we only show the form if needed
# 
#
if ($action eq "login") { 
  if ($logincomplain) { 
    print "Login failed.  Try again.<p>";
  } 
  if ($logincomplain or !$run) { 
    print start_form(-name=>'Login'),
      h2('Login to Portfolio'),
    "Name:",textfield(-name=>'user'), p,
    "Password:",password_field(-name=>'password'),p,
      hidden(-name=>'act',default=>['login']),
        hidden(-name=>'run',default=>['1']),
    submit,
      end_form;
  }
  print "<p><a href=\"portfolio.pl?act=base&run=1\">Return</a></p>";
}

##############################   Start of Portfolio Pages ####################################

#this function gets called by the javascript. leaving it here just in case we need to interact with the JS early on.
if ($action eq "interactionWithPerl") { 
  #print "<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\" type=\"text/javascript\"></script>";
  #print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";
  print "on main page";
}


#
# BASE
#
# The base action presents the overall page to the browser
# This is the "document" that the JavaScript manipulates
#
#
if ($action eq "base") { 
  # The Javascript portion of our app
  #
  #print "<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\" type=\"text/javascript\"></script>";

  #print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";
  
  #
  # And a div to populate with info about nearby stuff
  #
  #
  if ($debug) {
    # visible if we are debugging
    print "<div id=\"data\" style=\:width:100\%; height:10\%\"></div>";
  } else {
    # invisible otherwise
    print "<div id=\"data\" style=\"display: none;\"></div>";
  }

  #
  # User mods
  #
  #
  if ($user eq "anon") {
    print "<h2>Welcome to Stock Portfolio</h2>";
    print "<p>If you don't have an account, please <a href=\"portfolio.pl?act=create-account\">sign up</a></p>";
    print "<p>If you have an account, please <a href=\"portfolio.pl?act=login\">login</a></p>";
  } else {
    my @portfolioIDs;
    eval{
        @portfolioIDs = ExecSQL($dbuser, $dbpasswd, "select id from portfolios where username=?", "COL", $user);
    };
    print "<h2>Portfolios</h2>";
    #my (@portfolioIDs, $pfError) = GetPortfolios($user);
    for my $portfolioID (@portfolioIDs) { 
        print "<p><a href=\"portfolio.pl?act=viewPortfolio&PortfolioID=$portfolioID\">$portfolioID</a></p>";
    }
    print "<p><a href=\"portfolio.pl?act=addPortfolio\">Add a portfolio</a></p>";
    print "<hr>";
    print "<p>You are logged in as $user and can do the following:</p>";
    print "<p><a href=\"portfolio.pl?act=logout\">logout</a></p>";
    print "<p><a href=\"portfolio.pl?act=viewStock&stockID=blankStockName\">Browse Stocks</a></p>";
    print "<p><a href=\"portfolio.pl?act=addStockInfo\">Add Stock Info</a></p>";
  }

}

if ($action eq "addStockInfo"){
    if(!$run){
        print "<h2> Add Data To Model </h2>";
        print start_form(-name=>'addStockInfo'),
        "Symbol:",textfield(-name=>'symbol'), p,
        "Timestamp:",textfield(-name=>'timestamp'),p,
        "Open:",textfield(-name=>'open'),p,
        "High:",textfield(-name=>'high'),p,
        "Low:",textfield(-name=>'low'),p,
        "Close:",textfield(-name=>'close'),p,
        "Volume:",textfield(-name=>'volume'),p,
        hidden(-name=>'act',default=>['addStockInfo']),
        hidden(-name=>'run',default=>['1']),
        submit,
          end_form;
        print "<p><a href=\"portfolio.pl?act=base&run=1\">Return</a></p>";
    }else{
        my $symbol = param('symbol');
        my $timestamp = param('timestamp');
        my $open = param('open');
        my $high = param('high');
        my $low = param('low');
        my $close = param('close');
        my $volume = param('volume');


        my $error;
        $error=AddStockInfo($symbol, $timestamp, $open, $high, $low, $close, $volume);
        if ($error) { 
          print "Can't add stock info because: $error";
        } else {
          print "Added stock info for $symbol\n";
        }
        print "<p><a href=\"portfolio.pl?act=base&run=1\">Return</a></p>";
    }
}




if ($action eq "addPortfolio"){
    if(!$run){
        print "<h2> Add a portfolio</h2>";
        print start_form(-name=>'addPortfolio'), 
            "Name: ", textfield(-name=>'name'),
             p,
            hidden(-name=>'run',-default=>['1']),
            hidden(-name=>'act',-default=>['addPortfolio']),
            submit,
            end_form,
            hr;
        }else{
            my $pfName = param('name');
            my ($addStr, $addError) = AddPortfolio($pfName, $user);
            if(!$addError){
                print "<p>success!</p>";
            }else{
               print $addError;
            }
            print "<p><a href=\"portfolio.pl?act=base&run=1\">Return</a></p>";
        }
}

if ($action eq "viewPortfolio") { 
  # The Javascript portion of our app
  #
  print "<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\" type=\"text/javascript\"></script>";

  print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";


  if ($user eq "anon") {
    print "<h2>Welcome to Stock Portfolio</h2>";
    print "<p>If you don't have an account, please <a href=\"portfolio.pl?act=create-account\">sign up</a></p>";
    print "<p>If you have an account, please <a href=\"portfolio.pl?act=login\">login</a></p>";
  } else {
    my $portfolioID=param('PortfolioID');
    my @stockIDs;
    eval{
        @stockIDs = ExecSQL($dbuser, $dbpasswd, "select SYMBOL,AMNT from shares where username=? and portfolioID=?", "COL", $user,$portfolioID);
    };    
    print "<h2>Portfolio ID: $portfolioID</h2>";
    print "<hr> <h3> Stats </h3> <hr>";
    my @cashAmnt;
    eval{
        @cashAmnt = ExecSQL($dbuser, $dbpasswd, "select cash from portfolios where username=? and ID=?", "ROW", $user, $portfolioID);
    };
    print "<h3>Cash Balance: $cashAmnt[0]</h3>";
    print "<p><a href=\"portfolio.pl?act=addCash&PortfolioID=$portfolioID\">Add Cash</a></p>";
    print "<hr>";
    print "<h3>Stock Holdings</h3>";
    #print @stockIDs;
    print `./get_info.pl @stockIDs`;
    for my $stockID (@stockIDs){
         my @price = `./quote.pl $stockID`;
         print "<p> current price: " ;
         print substr @price[9],5;
         print "</p>";
         print "<p><a href=\"portfolio.pl?act=viewStock&stockID=$stockID&PortfolioID=$portfolioID\"> $stockID &emsp;", getStockAmountInPortfolio($user, $portfolioID, $stockID),"</a></p>";
    }
    print "<p><a href=\"portfolio.pl?act=tradeStock&PortfolioID=$portfolioID\">Add Stock</a></p>";
    print "<hr>";
    print "<p><a href=\"portfolio.pl?act=base\">Return to main page</a></p>";
  }

}

if ($action eq "addCash") {
    my $portfolioID=param('PortfolioID'); 
    print "<h2>Deposit</h2>";
    if(!$run){
        print start_form(-name=>'addCash'), 
            "Amount ", textfield(-name=>'amount'),
             p,
            hidden(-name=>'run',-default=>['1']),
            hidden(-name=>'act',-default=>['addCash']),
            hidden(-name=>'PortfolioID',-default=>$portfolioID),
            submit,
            end_form,
            hr;
    }else{
        my $cashAmnt = param('amount');
        my $addError = AddCash($portfolioID, $user, $cashAmnt);
        if(!$addError){
            print "<p>success!</p>";
            print $portfolioID;
        }else{
           print $addError;
        }
        print "<p><a href=\"portfolio.pl?act=viewPortfolio&PortfolioID=$portfolioID\">Return to portfolio</a></p>"; 
    }

}



if ($action eq "viewStock") { 
  # The Javascript portion of our app
  #
  print "<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\" type=\"text/javascript\"></script>";

  print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";


  if ($user eq "anon") {
    print "<h2>Welcome to Stock Portfolio</h2>";
    print "<p>If you don't have an account, please <a href=\"portfolio.pl?act=create-account\">sign up</a></p>";
    print "<p>If you have an account, please <a href=\"portfolio.pl?act=login\">login</a></p>";
  } elsif (!$run) {
    my $stockID=param('stockID');
    my $portfolioID=param('PortfolioID');
    $portfolioID = "" if !defined($portfolioID);
    $stockID = "" if !defined($stockID);

    print "Stock:", "<input type=\"text\" name=\"symbolForGraph\" value = $stockID><br>";
    print "<hr>";
    print "<h3>GRAPH</h3>";
    print "Select start date: <input type=\"date\" id=\"stockStartDate\" value=\"2015-01-01\"><br>";
    print "Select Interval: <input type=\"radio\" name=\"interval\" onClick=\"displayGraph()\" value=\"week\">Week <br> 
            <input type=\"radio\" name=\"interval\" onClick=\"displayGraph()\" value=\"month\">Month <br> 
            <input type=\"radio\" name=\"interval\" onClick=\"displayGraph()\" value=\"quarter\">Quarter <br> 
            <input type=\"radio\" name=\"interval\" onClick=\"displayGraph()\" value=\"year\">Year <br>
            <input type=\"radio\" name=\"interval\" onClick=\"displayGraph()\" value=\"fiveyears\">Five Years<br>";
    print "<div id = \"symbolDataSelection\"><label><input type=\"checkbox\" onClick=\"displayGraph()\" name=\"Historical\" value=\"Historical\">Historical</label><br>
    <label><input type=\"checkbox\" onClick=\"displayGraph()\" name=\"Added\" value=\"Current\">Current</label><br>
    <label><input type=\"checkbox\" onClick=\"displayGraph()\" name=\"Predicted\" value=\"Predicted\">Predicted</label><br>";
    print "<div id=\"chartdata\"></div>";


    print "<hr>";
    print "<h3>Buy and Sell Functionality</h3>";
    print start_form(-name=>'tradeStock', -action => 'portfolio.pl'),p,
            "Amount: ", textfield(-name=>'amount'),
            p,
            radio_group(
                -name    => 'stockAction',
                -values  => ['buy', 'sell'],
                -default => 'buy',
                -columns => 2,
                -rows    => 1,
            ),
            "Portfolio to add to: ", textfield(-name=>'portfolioID',-default=>$portfolioID),
            hidden(-name=>'run',-default=>['1']),
            hidden(-name=>'postact',-default=>['tradeStock']),
            hidden(-name=>'symbol',-default=>$stockID),
            submit,
            end_form,
            hr;
    print "<h3>Automated Strategy</h3>";
    print "<p><a href=\"portfolio.pl?act=testStrategy&stockID=$stockID\">Test Automated Strategy On $stockID</a></p>";
    print "<hr>";
    print "<p><a href=\"portfolio.pl?act=base\">Return to main page</a></p>";
  }else{
    my $stockSymbol = param('stockSymbol');
    my $historical= param('historical') == 1;
    my $current = param('current') == 1;
    my $predicted = param('predicted') == 1;
    my $startDate = param('startDate');
    my $endDate = param('endDate');
    ## trying out some sql
    
    my $databaseString = "";
    if (! $historical){
      $databaseString .= "--nohistorical";
    }
    if($current){
      $databaseString .= " --current";
    }
    if($predicted){
      $databaseString .= " --predicted";
      print "PRE", `./time_series_symbol_project.pl AAPL 4 AWAIT 200 AR 16` ,"ENDPRE";   
    }

    print "query being run: ./get_data.pl --open --high --low --close --vol --from=\"$startDate\" --to=\"$endDate\" $databaseString $stockSymbol";
    print `./get_data.pl --open --high --low --close --vol --from="$startDate" --to="$endDate" $databaseString $stockSymbol`;
    print `./shannon_ratchet.pl AAPL 1000 20`;

    #my $format = "raw";
    #my ($str,$error) = getSymbols($stockID,$format);
    #  if (!$error) {
    #   if ($format eq "table") { 
    #     print "<div id=\"symbolDataDiv\">";
    #     print "<h2>Symbol Data</h2>$str";
    #     print "</div>";
    #   } else {
    #     print $str;
    #   }
    #    }
  }
}



if ($action eq "tradeStock") { 
  # The Javascript portion of our app
  #
  print "<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\" type=\"text/javascript\"></script>";
  print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";

  if ($user eq "anon") {
    print "<h2>Welcome to Stock Portfolio</h2>";
    print "<p>If you don't have an account, please <a href=\"portfolio.pl?act=create-account\">sign up</a></p>";
    print "<p>If you have an account, please <a href=\"portfolio.pl?act=login\">login</a></p>";
  } elsif (!$run) {
    my $portfolioID=param('PortfolioID');
    $portfolioID = "" if !defined($portfolioID);
    print "<h3>Buy and Sell Stock</h3>";
    print start_form(-name=>'tradeStock', -action => 'portfolio.pl',
             -method  => 'POST'),p,
            "Stock Name: ", textfield(-name=>'symbol'),
            "Amount: ", textfield(-name=>'amount'),
            p,
            radio_group(
                -name    => 'stockAction',
                -values  => ['buy', 'sell'],
                -default => 'buy',
                -columns => 2,
                -rows    => 1,
            ),
            "Portfolio to add to: ", textfield(-name=>'portfolioID',-default=>$portfolioID),
            hidden(-name=>'run',-default=>['1']),
            hidden(-name=>'postact',-default=>['tradeStock']),

            submit,
            end_form,
            hr;
    print "<p><a href=\"portfolio.pl?act=base\">Return to main page</a></p>";
  }else{
    my $symbol=param('symbol');
    my $stockAction=param('stockAction');
    my $portfolioID=param('portfolioID');
    my $amount=param('amount');
    if($stockAction eq "sell"){
      $amount = 0 - $amount;
    }
    if (userHasStockInPortfolio($user, $portfolioID, $symbol)) { 
      print "$user had ", getStockAmountInPortfolio($user, $portfolioID, $symbol) , "of $symbol in $portfolioID originally";
      my $error = updateUserStock($amount, $user, $portfolioID, $symbol);
      if ($error) { 
           print "Can't update stock because: $error";
      } else {
           print "updated stock\n";
      }
    }else{
        my $error = addNewStockToPortfolio($symbol, $portfolioID, $user, $amount);
        if($error){
          print "could not add stock to portfolio"
        }else{
          print "successfully added stock to portfolio"
        }
    }
    print "<p><a href=\"portfolio.pl?act=base\">Return to main page</a></p>";

  }
}



if ($action eq "testStrategy") { 
  # The Javascript portion of our app
  #
  print "<script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js\" type=\"text/javascript\"></script>";

  print "<script type=\"text/javascript\" src=\"portfolio.js\"> </script>";


  if ($user eq "anon") {
    print "<h2>Welcome to Stock Portfolio</h2>";
    print "<p>If you don't have an account, please <a href=\"portfolio.pl?act=create-account\">sign up</a></p>";
    print "<p>If you have an account, please <a href=\"portfolio.pl?act=login\">login</a></p>";
  } elsif (!$run){
    my $stockID=param('stockID');
    print "<h2>Testing Shannon Ratchet</h2>";
     print start_form(-name=>'testStrategy'),p,
            "Stock Name: ", textfield(-name=>'symbol', -default=>$stockID),
            "Initial Cash: ", textfield(-name=>'initialcash'),
            "Trading Cost: ", textfield(-name=>'tradingcost'),
            hidden(-name=>'run',-default=>['1']),
            hidden(-name=>'act',-default=>['testStrategy']),
            submit,
            end_form,
            hr;
    print "<p><a href=\"portfolio.pl?act=viewStock&stockID=$stockID\">Return to stock view</a></p>";
  }else{
    my $symbol=param('symbol');
    my $initialcash=param('initialcash');
    my $tradingcost=param('tradingcost');

    print "instruction being run: ./shannon_ratchet.pl $symbol $initialcash $tradingcost", "<br>";
    print `./shannon_ratchet.pl $symbol $initialcash $tradingcost`;


    print "<p><a href=\"portfolio.pl?act=viewStock&stockID=$symbol\">Return to stock view</a></p>";
  }
  print "<hr>";
  print "<p><a href=\"portfolio.pl?act=base\">Return to main page</a></p>";
}

##################################################################################################


##############################   Start of Portfolio Functions ####################################
if ($action eq "create-account") {
  if (!$run) {
        print start_form(-name=>'CreateAccount'),
          h2('Create Account'), 
          "Name: ", textfield(-name=>'name'),
          p,
          "Email: ", textfield(-name=>'email'),
          p,
          "Password: ", textfield(-name=>'password'),
          p,
          hidden(-name=>'run',-default=>['1']),
          hidden(-name=>'act',-default=>['create-account']),
          submit,
          end_form,
          hr;
    } else {
      my $name=param('name');
      my $email=param('email');
      my $password=param('password');

      my $errorAdd = UserAdd($name,$password,$email);
      if ($errorAdd) { 
           print "Can't add user because: $errorAdd";
      } else {
           print "Added user $name $email\n";
      }
    }
  print "<p><a href=\"portfolio.pl?act=base&run=1\">Return</a></p>";
}

##################################################################################################



#
#
#
#
# Debugging output is the last thing we show, if it is set
#
#
#
#

print "</center>" if !$debug;

#
# Generate debugging output if anything is enabled.
#
#
if ($debug) {
  print hr, p, hr,p, h2('Debugging Output');
  print h3('Parameters');
  print "<menu>";
  print map { "<li>$_ => ".escapeHTML(param($_)) } param();
  print "</menu>";
  print h3('Cookies');
  print "<menu>";
  print map { "<li>$_ => ".escapeHTML(cookie($_))} cookie();
  print "</menu>";
  my $max= $#sqlinput>$#sqloutput ? $#sqlinput : $#sqloutput;
  print h3('SQL');
  print "<menu>";
  for (my $i=0;$i<=$max;$i++) { 
    print "<li><b>Input:</b> ".escapeHTML($sqlinput[$i]);
    print "<li><b>Output:</b> $sqloutput[$i]";
  }
  print "</menu>";
}

print end_html;

#
# The main line is finished at this point. 
# The remainder includes utilty and other functions
#

##############################  Original SQL Functions #######################################
#
# Add a user
# call with name,password,email
#
# returns false on success, error string on failure.
# 
# UserAdd($name,$password,$email)
#
sub UserAdd { 
  eval { ExecSQL($dbuser,$dbpasswd,
     "insert into pf_users (name,password,email) values (?,?,?)",undef,@_);};
  return $@;
}

#
# Delete a user
# returns false on success, $error string on failure
# 
sub UserDel { 
  eval {ExecSQL($dbuser,$dbpasswd,"delete from pf_users where name=?", undef, @_);};
  return $@;
}


###############################################################################################
sub AddPortfolio{
  my ($addName, $addUser) = @_;
  my @rows;
  eval {
    @rows = ExecSQL($dbuser, $dbpasswd, "insert into portfolios(id,username,cash) values(?,?,0)", undef,$addName,$addUser);
  
  };
  if ($@) { 
   return (undef,$@);
  } else {
     return (MakeRaw("new_portfolio","ROW",@rows),$@);
  }
}

sub GetPortfolios{
    my $qUser = @_;
    my @rows;
    eval{
        @rows = ExecSQL($dbuser, $dbpasswd, "select id from portfolios where username=?", undef, $user);
    };
    if ($@) { 
        return (undef,$@);
    }else {
        return (MakeRaw("portfolios","2D",@rows),$@);       
    }
}

sub getSymbols {
  my ($symbol,$format) = @_;
  my @rows;
  eval { 
    @rows = ExecSQL($dbuser, $dbpasswd, "select * from cs339.stocksdaily where SYMBOL=?",undef,$symbol);
  };
  
  if ($@) { 
    return (undef,$@);
  } else {
    if ($format eq "table") { 
      return (MakeTable("symbol_data","2D",
      ["symbol", "timestamp", "open", "high", "low", "close", "volume"],
      @rows),$@);
    } else {
      return (MakeRaw("symbol_data","2D",@rows),$@);
    }
  }
}


sub AddStockInfo{
  my ($symbol, $timestamp, $open, $high, $low, $close, $volume) = @_;
  my @rows;
  eval {
    @rows = ExecSQL($dbuser, $dbpasswd, "insert into newStockData(symbol,timestamp,open,high,low,close,volume) values(?,?,?,?,?,?,?)", undef,$symbol,$timestamp,$open,$high,$low,$close,$volume);
  };
  if ($@) { 
   return (undef,$@);
  } else {
     return (MakeRaw("new_stock_data","ROW",@rows),$@);
  }
}

sub userHasStockInPortfolio {
  my ($user, $portfolioID, $symbol) = @_;
  my @col;
  eval {@col=ExecSQL($dbuser,$dbpasswd, "select count(*) from shares where username=? and portfolioID=? and symbol=?","COL",$user,$portfolioID,$symbol);};
  if ($@) { 
    return 0;
  } else {
    return $col[0]>0;
  }
}

sub updateUserStock {
  my ($amnt, $user, $portfolioID, $symbol) = @_;
  my @rows;
  my @cash;
  eval {@rows=ExecSQL($dbuser,$dbpasswd, "update shares set amnt = amnt + ? where username=? and portfolioID=? and symbol=?",undef,$amnt, $user,$portfolioID,$symbol);};
  # update related cash amnt -Yang
  my @tmp = `./quote.pl $symbol`;
  my $price = substr @tmp[9],5;       
  my $money = $price * $amnt;
  my $balance = ExecSQL($dbuser, $dbpasswd, "select cash from portfolios where username=? and id=?", undef, $user, $portfolioID);
  if($balance < $money){
      print "you do not have enough balance";
      return(undef, $@);
  }
  eval{
      @cash = ExecSQL($dbuser, $dbpasswd, "update portfolios set cash = cash - ? where username=? and id=?", undef, $money, $user, $portfolioID);
  };
  if ($@) { 
   return (undef,$@);
  } else {
     return (MakeRaw("updated_stock_data","ROW",@rows),$@);
  }
}

sub getStockAmountInPortfolio {
  my ($user, $portfolioID, $symbol) = @_;
  my @col;
  eval {@col=ExecSQL($dbuser,$dbpasswd, "select amnt from shares where username=? and portfolioID=? and symbol=?","COL",$user,$portfolioID,$symbol);};
  if ($@) { 
    return 0;
  } else {
    return $col[0];
  }
}


# returns false on success, $error string on failure
sub addNewStockToPortfolio { 
  my ($symbol, $portfolioID, $user, $amount) = @_;
  eval { ExecSQL($dbuser, $dbpasswd, "insert into shares(symbol,portfolioID,username,amnt) values(?,?,?,?)", undef,$symbol,$portfolioID, $user,$amount);};
  return $@;
}


sub AddCash{
  my ($pfName, $pfUser,$cashAmnt) = @_;
  
  eval {
    ExecSQL($dbuser, $dbpasswd, "update portfolios SET cash=cash+? where id=? and username=?", undef,$cashAmnt,$pfName,$pfUser);
  };

  return $@;
}

################################################################################################


#
#
# Check to see if user and password combination exist
#
# $ok = ValidUser($user,$password)
#
#
sub ValidUser {
  my ($user,$password)=@_;
  my @col;
  eval {@col=ExecSQL($dbuser,$dbpasswd, "select count(*) from pf_users where name=? and password=?","COL",$user,$password);};
  if ($@) { 
    return 0;
  } else {
    return $col[0]>0;
  }
}


#
# Given a list of scalars, or a list of references to lists, generates
# an html table
#
#
# $type = undef || 2D => @list is list of references to row lists
# $type = ROW   => @list is a row
# $type = COL   => @list is a column
#
# $headerlistref points to a list of header columns
#
#
# $html = MakeTable($id, $type, $headerlistref,@list);
#
sub MakeTable {
  my ($id,$type,$headerlistref,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  if ((defined $headerlistref) || ($#list>=0)) {
    # if there is, begin a table
    #
    $out="<table id=\"$id\" border>";
    #
    # if there is a header list, then output it in bold
    #
    if (defined $headerlistref) { 
      $out.="<tr>".join("",(map {"<td><b>$_</b></td>"} @{$headerlistref}))."</tr>";
    }
    #
    # If it's a single row, just output it in an obvious way
    #
    if ($type eq "ROW") { 
      #
      # map {code} @list means "apply this code to every member of the list
      # and return the modified list.  $_ is the current list member
      #
      $out.="<tr>".(map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>" } @list)."</tr>";
    } elsif ($type eq "COL") { 
      #
      # ditto for a single column
      #
      $out.=join("",map {defined($_) ? "<tr><td>$_</td></tr>" : "<tr><td>(null)</td></tr>"} @list);
    } else { 
      #
      # For a 2D table, it's a bit more complicated...
      #
      $out.= join("",map {"<tr>$_</tr>"} (map {join("",map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>"} @{$_})} @list));
    }
    $out.="</table>";
  } else {
    # if no header row or list, then just say none.
    $out.="(none)";
  }
  return $out;
}


#
# Given a list of scalars, or a list of references to lists, generates
# an HTML <pre> section, one line per row, columns are tab-deliminted
#
#
# $type = undef || 2D => @list is list of references to row lists
# $type = ROW   => @list is a row
# $type = COL   => @list is a column
#
#
# $html = MakeRaw($id, $type, @list);
#
sub MakeRaw {
  my ($id, $type,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  $out="<pre id=\"$id\">\n";
  #
  # If it's a single row, just output it in an obvious way
  #
  if ($type eq "ROW") { 
    #
    # map {code} @list means "apply this code to every member of the list
    # and return the modified list.  $_ is the current list member
    #
    $out.=join("\t",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } elsif ($type eq "COL") { 
    #
    # ditto for a single column
    #
    $out.=join("\n",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } else {
    #
    # For a 2D table
    #
    foreach my $r (@list) { 
      $out.= join("\t", map { defined($_) ? $_ : "(null)" } @{$r});
      $out.="\n";
    }
  }
  $out.="</pre>\n";
  return $out;
}

#
# @list=ExecSQL($user, $password, $querystring, $type, @fill);
#
# Executes a SQL statement.  If $type is "ROW", returns first row in list
# if $type is "COL" returns first column.  Otherwise, returns
# the whole result table as a list of references to row lists.
# @fill are the fillers for positional parameters in $querystring
#
# ExecSQL executes "die" on failure.
#
sub ExecSQL {
  my ($user, $passwd, $querystring, $type, @fill) =@_;
  if ($debug) { 
    # if we are recording inputs, just push the query string and fill list onto the 
    # global sqlinput list
    push @sqlinput, "$querystring (".join(",",map {"'$_'"} @fill).")";
  }
  my $dbh = DBI->connect("DBI:Oracle:",$user,$passwd);
  if (not $dbh) { 
    # if the connect failed, record the reason to the sqloutput list (if set)
    # and then die.
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't connect to the database because of ".$DBI::errstr."</b>";
    }
    die "Can't connect to database because of ".$DBI::errstr;
  }
  my $sth = $dbh->prepare($querystring);
  if (not $sth) { 
    #
    # If prepare failed, then record reason to sqloutput and then die
    #
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't prepare '$querystring' because of ".$DBI::errstr."</b>";
    }
    my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  if (not $sth->execute(@fill)) { 
    #
    # if exec failed, record to sqlout and die.
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't execute '$querystring' with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr."</b>";
    }
    my $errstr="Can't execute $querystring with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  #
  # The rest assumes that the data will be forthcoming.
  #
  #
  my @data;
  if (defined $type and $type eq "ROW") { 
    @data=$sth->fetchrow_array();
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","ROW",undef,@data);}
    $dbh->disconnect();
    return @data;
  }
  my @ret;
  while (@data=$sth->fetchrow_array()) {
    push @ret, [@data];
  }
  if (defined $type and $type eq "COL") { 
    @data = map {$_->[0]} @ret;
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","COL",undef,@data);}
    $dbh->disconnect();
    return @data;
  }
  $sth->finish();
  if ($debug) {push @sqloutput, MakeTable("debug_sql_output","2D",undef,@ret);}
  $dbh->disconnect();
  return @ret;
}


######################################################################
#
# Nothing important after this
#
######################################################################

# The following is necessary for DBD::Oracle 
#
BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="cs339";
  $ENV{PORTF_DBUSER}="aly155";
  $ENV{PORTF_DBPASS}="zaC43gcHq";

  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
}

