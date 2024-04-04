# Infrastructure for SOCRA Workshops

- Fill in `students.csv` with the list of `username`. 1 line will create 1 instance

```csv
username
student1
student2
...

```

> Note: file needs to end with `\n`

- Create all SSH key pairs:

```bash
./create-ssh-keys.sh ./students.csv
```

- Run the terraform code:

```sh
terraform apply
```
