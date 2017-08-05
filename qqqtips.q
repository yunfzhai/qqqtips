
/ util.q
/ ----------------------------------------------------------------------------
/ NOTE
/ functional select, exec, update:
/ ?[ table; whereConditions; groupBy; selectedColumns]
/ ![ table; whereConditions; groupBy; updatedColumns]
/ example:
/ select c from t where x <= 1
/ -> ?[t; enlist (<=; `x; 1); (); (enlist `c)!enlist `c)];
/
/ exec c from t where x <= 1
/ -> ?[t; enlist (<=; `x; 1); (); `c];
/
/ exec last c from t where x <= 1, z = `v
/ -> ?[t; enlist[(<=; `x; y); (=; `z; enlist `v)]; (); (last;`c)];
/ ----------------------------------------------------------------------------
\
/ check if the current kdb is HDB or RDB
is_hdb: { @[value;`.Q.pf;`rdb]~`date};

/ check if the value x is defined
existed: { not () ~ key x }

/ calculate the difference between current row and the next row
/ this is useful for determining the duration of each state transition
diff: { 1 rotate 1_deltas (1#x), x};

/ combine a date and a time strings into a datetime datum
/ "2015.08.31" + "09:00" -> 2015.08.31T09:00:00.0
to_datetime: {[d;t] :"p"$(trim[d] + "T"$trim[t]) };

/ state machine with state transition table
fsm: { ([ state: `s0`s1] event0: `s0`s1; event1: `s1`s0)[x;y] };

/ a function applies over a list of arguments and return a dictionary with the given id(s)
/ it's useful for retrieving the result for each of the id as we wish
apply: {[f;ids;args1;args2] ![ids; f'[ids;args1;args2]] };

/ perform a query/function to another remote kdb within a query
remote_q: {[host;f;arg1;arg2]
    h: hopen host;
    t: h (f;arg1;arg2);
    hclose h;
    :t
};

/ search for table whose name matches the regex
lookup: { {x where {x like y}[x;y]}[tables[];x] }

/ check if a date is weekday
is_weekday: { 1 < x mod 7 };

/ row count for each table in the db
rowcount: { ![tables[]; { ?[x; (); (); (count;`i)] } each tables[]] };


t:([]id:("abc123";"geh789";"def678";"abc321";"xyz1010");p:5?10)
?[t;enlist (any;(like/:;`id;enlist ("abc*";"def*")));0b;()]
id       p
----------
"abc123" 8
"def678" 9
"abc321" 5


q)t:([]col1:1 1 3 3 3 7 7 1;col2: 1 4 4 4 6 7 6 4; col3: 2 1 2 1 2 2 2 2; col4: `a`b`c`d`d`d`d`d;col5: 2 2 3 6 1 7 7 8)
q)
// Retrieve rows where col1 and col4 changed
q)?[t;enlist (all;(enlist,differ,/:`col1`col4));0b;()]
col1 col2 col3 col4 col5
------------------------
1    1    2    a    2
3    4    2    c    3
q)
q)
// Retrieve rows where col1 or col4 changed
q)?[t;enlist (any;(enlist,differ,/:`col1`col4));0b;()]
col1 col2 col3 col4 col5
------------------------
1    1    2    a    2
1    4    1    b    2
3    4    2    c    3
3    4    1    d    6
7    7    2    d    7
1    4    2    d    8

getDiffs:{[tab;fns;fk;seed;d]
        coll:`date,fk,fns;
        t:?[tab;enlist(=;`date;d);0b;{x!x}coll];
        ?[fk xasc t uj seed;enlist(any;enlist,differ,/:fns);0b;{x!x}coll]}


getPartDiffs:{[tab;fns;fk;seed;dates]
        seed getDiffs[tab;fns;fk;;]/ dates}


getFullDiffs:{[tab;fns;fk;seed;dates;fnr]
        res:getPartDiffs[tab;;fk;seed;dates] peach fnr cut fns;
        uj/[(`date,fk) xkey/:res]}


main:{[tab;sd;ed;fns;fk;fnr]
        k:`date,fk;
        dates:sd+1+til (ed-sd);
        seed:?[tab;enlist (=;`date;sd);0b;x!x:k,fns];
        res:getFullDiffs[tab;fns;fk;seed;dates;fnr];
        unchangedKeys:?[res;();();(distinct;fk)];
        (k xkey ?[seed;((=;`date;sd);(not;(in;fk;enlist unchangedKeys)));0b;()]) uj res}



q)t:main[`ref;2017.02.01;2017.02.28;`col1`col2`col3`col4`col5`col6;`id;3]



getData:{[f;k]
        tabs:tables[];
        f: f,k;
        d: tabs! cols each tabs;
        d:f where each f in/: d;
        d:(where 1<count each d)#d;
        uj/[{[t;f;k] k xkey ?[t;();0b;f!f]}[;;k]'[key d;value d]]}


q)getData[`col1`col2;`date`sym]


q)tab:([]date:2016.09.12 2016.09.12 2016.09.12 2016.09.13 2016.09.13 2016.09.13 2016.09.13 2016.09.14 2016.09.14 2016.09.14 2016.09.14 2016.09.15 2016.09.15 2016.09.15 2016.09.15 2016.09.15 2016.09.16 2016.09.16 2016.09.16 2016.09.16 2016.09.19 2016.09.19 2016.09.19 2016.09.19;sym:`m`c`e`m`b`c`e`m`b`c`e`m`b`f`c`e`m`b`c`e`m`b`c`e;v:401.048 200.761 10.326 414.167 4.14167 207.146 10.283 366.41 3.6641 190.268 10.336 337.372 3.37372 400 195.094 9.955 501.436 5.01436 301.386 27.851 316.3 3.163 179.112 7.809;p:21.5904 52.1189 183.2507 21.2702 12.1232 51.5525 180.6675 21.2577 12.1159 51.7377 180.3477 21.4726 12.2702 10 52.4969 182.1248 21.3916 12.2478 52.4457 181.238 21.3912 12.3253 52.3503 181.2017)

q)res1:select wav:v wavg p by date from tab
q)res1
date      | wav
----------| --------
2016.09.12| 34.32981
2016.09.13| 33.6559
2016.09.14| 34.24265
2016.09.15| 24.67822
2016.09.16| 37.86343
2016.09.19| 34.7495

q)select sym,v,p by date from tab
date      | sym        v                                 p
----------| --------------------------------------------------------------------------------
2016.09.12| `m`c`e     401.048 200.761 10.326            21.5904 52.1189 183.2507
2016.09.13| `m`b`c`e   414.167 4.14167 207.146 10.283    21.2702 12.1232 51.5525 180.6675
2016.09.14| `m`b`c`e   366.41 3.6641 190.268 10.336      21.2577 12.1159 51.7377 180.3477
2016.09.15| `m`b`f`c`e 337.372 3.37372 400 195.094 9.955 21.4726 12.2702 10 52.4969 182.1248
2016.09.16| `m`b`c`e   501.436 5.01436 301.386 27.851    21.3916 12.2478 52.4457 181.238
2016.09.19| `m`b`c`e   316.3 3.163 179.112 7.809         21.3912 12.3253 52.3503 181.2017


q)select date, sym, validSym:(inter':) sym from `date xgroup tab
date       sym        validSym
--------------------------------
2016.09.12 `m`c`e     `symbol$()
2016.09.13 `m`b`c`e   `m`c`e
2016.09.14 `m`b`c`e   `m`b`c`e
2016.09.15 `m`b`f`c`e `m`b`c`e
2016.09.16 `m`b`c`e   `m`b`c`e
2016.09.19 `m`b`c`e   `m`b`c`e

q)res2:1!select date,adjWav:{wavg'[x@'z;y@'z]}[v;p;sym?'(inter':) sym] from `date xgroup tab
q)res2:
date      | adjWav
----------| --------
2016.09.12|
2016.09.13| 33.7971
2016.09.14| 34.24265
2016.09.15| 35.43554
2016.09.16| 37.86343
2016.09.19| 34.7495


q)res1,'res2
date      | wav      adjWav
----------| -----------------
2016.09.12| 34.32981
2016.09.13| 33.6559  33.7971
2016.09.14| 34.24265 34.24265
2016.09.15| 24.67822 35.43554
2016.09.16| 37.86343 37.86343
2016.09.19| 34.7495  34.7495


q)-10#select date,ma:21 mavg adjWav,minim:21 mmin adjWav,maxim:21 mmax adjWav,devi:21 mdev adjWav from 1_t
date       ma       minim    maxim    devi
----------------------------------------------
2017.02.17 44.39342 42.59418 46.12253 1.053702
2017.02.21 44.37788 42.59418 46.12253 1.032939
2017.02.22 44.42241 42.59418 46.12253 1.044719
2017.02.23 44.39069 42.59418 46.12253 1.077618
2017.02.24 44.32905 42.59418 46.12253 1.125346
2017.02.27 44.27849 42.59418 46.12253 1.147834
2017.02.28 44.21612 42.59418 46.12253 1.113893
2017.03.01 44.33964 42.59418 46.12253 1.106236
2017.03.02 44.41428 42.59418 46.12253 1.078212

q)mwin:{[f;w;l] f each { 1_x,y }\[w#0n;`float$l]}
q)mwin[::;3;100+til 5]
        100
    100 101
100 101 102
101 102 103
102 103 104
q)


q)mwin[avg;3;100+til 10] ~ (3 mavg 100+til 10)
1b
q)
q)wa:{w:1%1+reverse til count x;w wavg x}
q)
q)-10#select date,wma:mwin[wa;5;adjWav] from t
date       wma
------------------
2017.02.17 45.597
2017.02.21 45.655
2017.02.22 45.4277
2017.02.23 44.3347
2017.02.24 43.7596
2017.02.27 43.5462
2017.02.28 43.7518
2017.03.01 44.3833
2017.03.02 44.5088
2017.03.03 44.0903
