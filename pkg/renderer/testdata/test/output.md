# Workflow

- [Given we choose to go to the moon](#step-1)
- &nbsp;&nbsp;[And do the other things](#step-2)
- [When we organize and measure the best of our energies and skills](#step-3)
- [Then we intend to win](#step-4)

<a name="step-1"></a>
## Given we choose to go to the moon



### Outputs

- `money_allocated`: The money allocated to the project



<a name="step-2"></a>
## And do the other things

But why, some say, the moon? Why choose this as our goal? And they may well ask why climb the highest mountain? Why, 35 years ago, fly the Atlantic? Why does Rice play Texas?

Other difficult things for the advancement of mankind, those can include but are not limited to:
* climbing tall mountains
* flying across the Atlantic
* Rice playing Texas

This step collects all other things that need to be done.


### Inputs

- `the_other_things_to_do`: The other things to do



### Outputs

- `the_other_things_done`: Whether the other things have been done



### Script

```bash
OUTPUT=$(mktemp)

# export INPUT_the_other_things_to_do=

echo "Doing the other things..."
collect_other_things() {
  echo "Other things done"
}
collect_other_things


# echo "# Outputs"
# cat "$OUTPUT"
# rm -f "$OUTPUT"

```

<a name="step-3"></a>
## When we organize and measure the best of our energies and skills



### Inputs

- `money_allocated`: The money allocated to the project



### Outputs

- `energies_measured`: Whether energies and skills have been measured



<a name="step-4"></a>
## Then we intend to win



### Inputs

- `energies_measured`: Whether energies and skills have been measured


- `the_other_things_done`: Whether the other things have been done



### Outputs

- `mission_successful`: Whether the mission was successful
