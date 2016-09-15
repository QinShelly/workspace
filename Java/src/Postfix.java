package compiler;

import java.io.IOException;

public class Postfix {
public static void main(String[] args) throws IOException
{
System.out.print("input expr:\n");
Parser parser = new Parser();
parser.expr();
System.out.print("\nend");
}
}

class Parser {
static int lookahead;

public Parser() throws IOException
{
lookahead = System.in.read();

}

void expr() throws IOException{
term();
while (true){
if (lookahead == '+'){
match('+');
term();
System.out.write('+');
}
if (lookahead == '-'){
match('-');
term();
System.out.write('-');
}
else return;
}
}

void term() throws IOException{
if(Character.isDigit((char)lookahead)){
System.out.write((char)lookahead);
match(lookahead);
}
else throw new Error("Syntax error");
}

void match(int t) throws IOException{
if (lookahead == t){
lookahead = System.in.read();
}
else throw new Error("Syntax error");
}
}
