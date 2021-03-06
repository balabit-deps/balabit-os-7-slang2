() = evalfile ("inc.sl");

testing_feature ("Associative Arrays");

static define key_to_value (k)
{
   return "<<<" + k + ">>>";
}

static define value_to_key (v)
{
   strcompress (v, "<>");
}

static define add_to_x (x, k)
{
   x[k] = key_to_value(k);
}

static variable Default_Value = "****Default-Value****";

define setup (type)
{
   variable x = Assoc_Type [type, Default_Value];
   variable num = 0;

   while (num < 512)
     {
	add_to_x (x, sprintf ("key_%d", num));
	num++;
     }

   add_to_x (x, "foo"); num++;
   add_to_x (x, "bar"); num++;
   add_to_x (x, "silly"); num++;
   add_to_x (x, "cow"); num++;
   add_to_x (x, "dog"); num++;
   add_to_x (x, "chicken"); num++;

   variable i = 0;
   while (i < 512)
     {
	assoc_delete_key (x, sprintf ("key_%d", i)); num--;
	i += 2;
     }

   if (length (x) != num)
     {
	failed ("length(x)");
     }
   assoc_delete_key (x, "cow"); num--;
   if (length(x) != num)
     {
	failed ("length after assoc_delete_key");
     }
   add_to_x (x, "cow");
   return x;
}

static variable X;

% Test create/destuction of arrays
loop (3) X = setup (Any_Type);

loop (3) X = setup (String_Type);

static variable k, v;

foreach k,v (X)
{
   if ((k != value_to_key(v)) or (v != key_to_value (k))
       or (X[k] != v))
     failed ("foreach");
}

foreach k (X) using ("keys")
{
   if (X[k] != key_to_value (k))
     failed ("foreach using keys");
}

foreach k,v (X) using ("keys", "values")
{
   if ((k != value_to_key(v)) or (v != key_to_value (k))
       or (X[k] != v))
     failed ("foreach using keys, values");
}

k = assoc_get_keys (X);
v = assoc_get_values (X);

static variable i;
_for i (0, length(k)-1, 1)
{
   if (v[i] != X[k[i]])
     failed ("assoc_get_keys/values");
   assoc_delete_key (X, k[i]);
}

if (length (X) != 0)
  error ("assoc_delete_key failed");

if (X["*******************"] != Default_Value)
  failed ("default value");

static define eqs (a, b)
{
   variable len;
   len = length (a);
   if (len != length (b))
     return 0;

   len == length (where (a == b));
}

static define neqs (a, b)
{
   not (eqs (a, b));
}

static define store_and_test (a, indx, value)
{
   a[indx] = value;
   if (typeof (value) != typeof(a[indx]))
     failed ("typeof (value)");
   if (neqs (a[indx], value))
     failed ("a[indx] != value");
}

X = Assoc_Type[];

store_and_test (X, "string", "string");
store_and_test (X, "array", ["a", "b", "c"]);
store_and_test (X, "int", 3);
#ifexists Complex_Type
store_and_test (X, "z", 3+2i);
#endif

static variable V = assoc_get_values (X);
static variable K = assoc_get_keys (X);

static variable i;

_for i (0, length(X)-1, 1)
{
   if (neqs(X[K[i]], @V[i]))
     failed ("assoc_get_values");
}

define test_arith ()
{
   variable a = Assoc_Type[Int_Type, 1];
   a["foo"] += 3;
   if (a["foo"] != 4)
     failed ("a[foo] += 3");

   a["foo"]--;
   if (a["foo"] != 3)
     failed ("a[foo]--");

   a["foo"]++;
   if (a["foo"] != 4)
     failed ("a[foo]++");

   a = Assoc_Type [Array_Type, [1,2]];

   a["bar"] += 3;
   ifnot (_eqs (a["bar"], [1,2] + 3))
     failed ("a[bar] += 3");

   a["bar"]++;
   ifnot (_eqs (a["bar"], [1,2] + 3 + 1))
     failed ("a[bar]++");
}
test_arith ();

private define check_assoc_values (a, key_value_pairs)
{
   variable key, expected_value, v, i;

   _for i (0, length(key_value_pairs)-1, 2)
     {
	key = key_value_pairs[i];
	expected_value = key_value_pairs[i+1];

        % test value seen by the interpreter
        v = a[key];
	ifnot (__is_same (v, expected_value))
	  {
	     failed ("api_created assoc's value (key=%S) was %S, expected %S",
		     key, v, expected_value);
	  }

        % test value seen by SLang_assoc_get
	v = api_assoc_get (a, key);
	ifnot (__is_same (v, expected_value))
	  {
	     failed ("api_assoc_get (key=%S) produced %S, expected %S",
		     key, v, expected_value);
	  }
     }
}

private define test_api_create_assoc_without_default_value ()
{
   variable key_value_pairs =
     {
	"foo", 1,
	"bar", PI,
	"complex", 2+3i,
	"string", "foobar",
	"array", [1,2,3,4],
	"struct", struct {foo, bar},
     };
   variable a = api_create_asssoc (__push_list (key_value_pairs));

   loop (10) check_assoc_values (a, key_value_pairs);
}
test_api_create_assoc_without_default_value ();

private define test_api_create_assoc_with_default_value ()
{
   variable key_value_pairs =
     {
	"foo", "1",
	"bar", "3.141592653589793",
	"complex", "(2 + 3i)",
	"string", "foobar",
	"array", "Integer_Type[4]",
	"struct", "Struct_Type with 2 fields",
     };

   variable default_value = "*default*";
   variable a = api_create_asssoc (__push_list (key_value_pairs), default_value);

   list_join (key_value_pairs,
	      {"bla", default_value, "blabla", default_value});

   loop (10) check_assoc_values (a, key_value_pairs);
}
test_api_create_assoc_with_default_value ();

test_api_push_and_pop_assoc ();  % entirely defined in assoc.c

private define test_api_pop_and_push_assoc ()
{
   variable a1 = Assoc_Type[Integer_Type, 42];
   a1;
   variable a2 = api_pop_and_push_assoc ();
   ifnot (__is_same (a1, a2))
     {
	failed ("api_push_and_pop_assoc");
     }
}
test_api_pop_and_push_assoc ();

print ("Ok\n");

exit (0);
